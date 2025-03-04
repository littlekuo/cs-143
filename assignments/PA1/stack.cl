(*
 *  CS164 Fall 94
 *
 *  Programming Assignment 1
 *    Implementation of a simple stack machine.
 *
 *  Skeleton file
 *)

 class List {
   -- Define operations on empty lists.
   isNil() : Bool { true };
   head()  : String { { abort(); "0"; } };
   tail()  : List { { abort(); self; } };

   cons(i : String) : List {
      (new Cons).init(i, self)
   };

};


class Cons inherits List {
   car : String; -- The element in this list cell
   cdr : List;	-- The rest of the list

   isNil() : Bool { false };
   head()  : String { car };
   tail()  : List { cdr };

   init(i : String, rest : List) : List {
      {
	 car <- i;
	 cdr <- rest;
	 self;
      }
   };
};


class StackCommand {
    stack : List;
    helper: A2I;
    io: IO;
    execute(str : String) : Object {
        if(str = "x") then { self; } else
        if(str = "e") then 
        {   
            if(stack.isNil()) then { self; } else

            -- No error handling
            if(stack.head() = "+") then 
            {
                stack <- stack.tail();
                let op1 : Int <- helper.a2i(stack.head()) in {
                       stack <- stack.tail();
                       let op2 : Int <- helper.a2i(stack.head()) in {
                            stack <- stack.tail().cons(helper.i2a(op1 + op2));
                       };
                };
            } else 
            if(stack.head() = "s") then {
                stack <- stack.tail();
                let str1 : String <- stack.head() in {
                    stack <- stack.tail();
                    let str2 : String <- stack.head() in {
                        stack <- stack.tail().cons(str1).cons(str2);
                    };
                };
            }
            else {self;}
            fi fi fi;
            getStr();
        } else 
        if(str = "d") then {
             print_stack(stack);
             getStr();
        } else {
            stack <- stack.cons(str);
            getStr();
        } 
        fi fi fi
    };


    getStr():Object {
        let str : String <- (new IO).in_string() in {
           execute(str);
        }
    };

    print_stack(l : List) : Object {
        let ls : List <- l in {
            while (not ls.isNil()) loop {
                io.out_string(ls.head());
                io.out_string("\n");
                ls  <- ls.tail();
            }
            pool;
            self;
        }
   };

   init () : StackCommand {
    {
       stack <- new List;
       helper <- new A2I;
       io <- new IO;
       self;
    }   
   };
};


class Main inherits IO {
   command: StackCommand;

   main() : Object {
    {
      command <- new StackCommand;
      command.init();
      command.getStr();
    }  
   };
};
