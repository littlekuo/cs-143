/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;
int comment_nesting;

/*
 *  Add Your own definitions here
 */ 
bool handle_string_too_long();

%}
%option noyywrap

/*
 * Define names for regular expressions here.
 */
%x STRING_NORMAL STRING_ESCAPE
%x BLOCK_COMMENT

DARROW          =>
ASSIGN          <-
LE              <=
PLUS            "+"
SLASH           "/"
MINUS           "-"
STAR            "*"
EQ              "="
LT              "<"
DOT             "."
TILDE           "~"
COMMA           ","
SEMI            ";"
COLON           ":"
LPAREN          "("
RPAREN          ")"
AT              "@"
LBRACE          "{"
RBRACE          "}"

%%

 /*
  *  Nested comments
  */
"(*" {
    BEGIN(BLOCK_COMMENT);
    comment_nesting = 1;
}

<BLOCK_COMMENT>{
"(*"    { comment_nesting++; }
"*)"    { 
    if (--comment_nesting == 0) {
        BEGIN(INITIAL);
    }
}
<<EOF>> {
    yylval.error_msg = "EOF in comment";
    BEGIN(INITIAL);
    return ERROR; 
}
\n  { curr_lineno++; }
.   {/* ignore */}
}

"*)" {
    yylval.error_msg = "Unmatched *)";
    return ERROR;
}


 /*
  *  The multiple-character operators.
  */
{DARROW}		{ return (DARROW); }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
(?i:class)       { return (CLASS); }
(?i:else)        { return (ELSE); }
(?i:fi)          { return (FI); }
(?i:if)          { return (IF); }
(?i:in)          { return (IN); }
(?i:inherits)    { return (INHERITS); }
(?i:let)         { return (LET); }
(?i:loop)        { return (LOOP); }
(?i:pool)        { return (POOL); }
(?i:then)        { return (THEN); }
(?i:while)       { return (WHILE); }
(?i:case)        { return (CASE); }
(?i:esac)        { return (ESAC); }
(?i:of)          { return (OF); }
(?i:new)         { return (NEW); }
(?i:isvoid)      { return (ISVOID); }
(?i:not)         { return (NOT); }

[0-9]+          {
                    yylval.symbol = inttable.add_string(yytext);
                    return (INT_CONST);
                }
t[rR][uU][eE]          { yylval.boolean = 1; return BOOL_CONST; } 
f[aA][lL][sS][eE]      { yylval.boolean = 0; return BOOL_CONST; }

[A-Z][a-zA-Z0-9_]* {
    yylval.symbol = idtable.add_string(yytext);
    return TYPEID;
}

[a-z][a-zA-Z0-9_]* {
    yylval.symbol = idtable.add_string(yytext);
    return OBJECTID;
}

{ASSIGN}		{ return (ASSIGN); }
{LE}		{ return (LE); }

{PLUS}		{ return (yytext[0]); }
{SLASH}		{ return (yytext[0]); } 
{MINUS}		{ return (yytext[0]); }
{STAR}		{ return (yytext[0]); }
{EQ}		  { return (yytext[0]); }
{LT}		  { return (yytext[0]); }
{DOT}		  { return (yytext[0]); }
{TILDE}		{ return (yytext[0]); }
{COMMA}		{ return (yytext[0]); }
{SEMI}	  { return (yytext[0]); }
{COLON}		{ return (yytext[0]); }
{LPAREN}	{ return (yytext[0]); }
{RPAREN}	{ return (yytext[0]); }
{AT}      { return (yytext[0]); }
{LBRACE}	{ return (yytext[0]); }
{RBRACE}	{ return (yytext[0]); }

 /*
  *  ignore whitespace
  */
\n    { curr_lineno++; }  
[ \f\r\t\v]+	{ /* ignore whitespace */ }


"--"     { 
             int c;
             while ((c = yyinput()) != '\n' && c != EOF);
             if (c == '\n') curr_lineno++;
         }

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */
\" {
    BEGIN(STRING_NORMAL);
    memset(string_buf, 0, sizeof(string_buf));
    string_buf_ptr = string_buf;
}

<STRING_NORMAL>{
    \\ { BEGIN(STRING_ESCAPE); }  // enter the escape state
    \" {  
        *string_buf_ptr++ = '\0';
        yylval.symbol = stringtable.add_string(string_buf);
        BEGIN(INITIAL);
        return STR_CONST;
    }
    \n {  
        yylval.error_msg = "Unterminated string constant";
        curr_lineno++;
        BEGIN(INITIAL);
        return ERROR;
    }
    <<EOF>> {
        yylval.error_msg = "EOF in string constant";
        BEGIN(INITIAL);
        return ERROR;
    }
    . {  
        *string_buf_ptr++ = yytext[0];
        // check if string is too long
        if (handle_string_too_long()) {  
            BEGIN(INITIAL); 
            return ERROR;
        }
    }
}

<STRING_ESCAPE>{
    n  { *string_buf_ptr++ = '\n'; BEGIN(STRING_NORMAL); if (handle_string_too_long()) {  BEGIN(INITIAL); return ERROR;} }
    t  { *string_buf_ptr++ = '\t'; BEGIN(STRING_NORMAL); if (handle_string_too_long()) {  BEGIN(INITIAL); return ERROR;} }
    b  { *string_buf_ptr++ = '\b'; BEGIN(STRING_NORMAL); if (handle_string_too_long()) {  BEGIN(INITIAL); return ERROR;} }
    f  { *string_buf_ptr++ = '\f'; BEGIN(STRING_NORMAL); if (handle_string_too_long()) {  BEGIN(INITIAL); return ERROR;} }
    \n { curr_lineno++;            BEGIN(STRING_NORMAL); if (handle_string_too_long()) {  BEGIN(INITIAL); return ERROR;} }  // 转义换行
    \" { *string_buf_ptr++ = '"';  BEGIN(STRING_NORMAL); if (handle_string_too_long()) {  BEGIN(INITIAL); return ERROR;} }
    \\ { *string_buf_ptr++ = '\\'; BEGIN(STRING_NORMAL); if (handle_string_too_long()) {  BEGIN(INITIAL); return ERROR;} }
    0  {
        yylval.error_msg = "String contains null character";
        char temp;
        while ((temp = yyinput()) != '"' && temp != '\n' && temp != EOF);
        if (temp == '\n') curr_lineno++;
        BEGIN(INITIAL);
        return ERROR;
    }
    <<EOF>> {
        yylval.error_msg = "EOF in string constant";
        BEGIN(INITIAL);
        return ERROR;
    }
    .  { *string_buf_ptr++ = yytext[0]; BEGIN(STRING_NORMAL); if (handle_string_too_long()) {  BEGIN(INITIAL); return ERROR;} }  // 普通转义字符
}

. { // 未识别的字符
    yylval.error_msg = yytext;
    return ERROR;
}

%%
bool handle_string_too_long() {
    if (string_buf_ptr - string_buf >= MAX_STR_CONST) {
        yylval.error_msg = "String constant too long";
        char c;
        while ((c = yyinput()) != '"' && c != '\n' && c != EOF);
        if (c == '\n') curr_lineno++;
        return true;
   }
   return false;
}
