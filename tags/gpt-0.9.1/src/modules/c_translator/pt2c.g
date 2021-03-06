/*
 *   Copyright (C) 2003-2006 by Thiago Silva                               *
 *   thiago.silva@kdemal.net                                               *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             *
                                                                           */


header {
  #include "PortugolAST.hpp"
  #include "SymbolTable.hpp"
  #include <string>
  #include <sstream>
  #include <map>
  #include <list>
  using namespace std;

  typedef struct production_t {
      //union {
      pair<int, list<string> > primvars;
      pair<int, pair< list<string>, list<string> > > matrizvars;//pair<type, pair<list<ids>,list<dims> > >
      pair<int, list<string> > tipo_matriz; //pair<type, list<dimsize> >
      pair<int, string> lvalue;    //pair<type, text> : ex TIPO_INTEIRO,"a[1][2]".
      pair<int, string> fcall; //pair<type, text>
      pair<bool,string> passo;
      pair<int, string> expr;
    //}
  } production;
}

options {
  language="Cpp";
}

class Portugol2CWalker extends TreeParser;
options {
  importVocab=Portugol;  // use vocab generated by lexer
  ASTLabelType="RefPortugolAST";
  noConstructors=true;
  genHashLines=false;//no #line
}

{
  public:
  Portugol2CWalker(SymbolTable& st) 
    : stable(st) { }

  private:

  SymbolTable& stable;

  int _currentScopeType;

  string _currentScope;

  string _indent;

  stringstream _scope_init_stms;

  stringstream _txt;

  stringstream _head;


  void indent() {
    _indent += "   ";
  }

  void unindent() {
    _indent = _indent.substr(0, _indent.length()-3);
  }

  void init(const string& name)  {
    stringstream s;
    s << "/* algoritmo " << name << " */\n\n";
    s << "#define _GNU_SOURCE\n"; //nescessario para evitar gcc:warning em getline()
    s << "#include <stdio.h>\n";
    s << "#include <string.h>\n";
    s << "#include <stdarg.h>\n";
    s << "#include <stdlib.h>\n\n";
    s << "typedef short int boolean;\n";
    s << "#ifndef TRUE\n";
    s << " #define TRUE 1\n";
    s << "#endif\n";
    s << "#ifndef FALSE\n";
    s << " #define FALSE 0\n";
    s << "#endif\n\n";
    s << "int idx = 0;\n"
         "char** allocated = NULL;\n"
         "void collect(char* str) {\n"
         "  allocated = (char**) realloc((void*)allocated, sizeof(char**)*(idx+1));\n"
         "  if(!allocated) {\n"
         "    fprintf(stderr, \"Erro ao alocar mem�ria. Abordando...\\n\");\n"
         "  }\n"
         "  allocated[idx++] = str;\n"
         "}\n";
    s << "void cleanup() {\n"
         "  int i;\n"
         "  for(i = 0; i < idx; i++) {\n"
         "    free(allocated[i]);\n"
         "  }\n"
         "  free(allocated);\n"
         "}\n\n";
    s << "void matrix_cpy__(void *src, void* dest, int type, int size) {\n"
         "   int i;\n"
         "   int *ds,*dd;\n"
         "   double *fs,*fd;\n"
         "   char *cs,*cd;\n"
         "   boolean *bs,*bd;\n"          
         "   switch(type) {\n"
         "     case 'i':\n"
         "       ds = (int*) src;\n"
         "       dd = (int*) dest;\n"
         "       for(i = 0; i < size; i++) dd[i] = ds[i];\n"
         "       break;\n"
         "     case 'f':\n"
         "       fs = (double*) src;\n"
         "       fd = (double*) dest;\n"
         "       for(i = 0; i < size; i++) fd[i] = fs[i];\n"
         "       break;\n"
         "     case 'c':\n"
         "       cs = (char*) src;\n"
         "       cd = (char*) dest;\n"
         "       for(i = 0; i < size; i++) cd[i] = cs[i];\n"
         "       break;\n"
         "     case 'b':\n"
         "       bs = (boolean*) src;\n"
         "       bd = (boolean*) dest;\n"
         "       for(i = 0; i < size; i++) bd[i] = bs[i];\n"
         "       break;\n"
         "     default:\n"
         "       fprintf(stderr, \"bug: tipo nao suportado: %c\\n\", type);\n"
         "       exit(1);\n"
         "   }\n"
         "}\n";
    s << "void matrix_init__(void *matrix, int type, int size) {\n"
         "   int i;\n"
         "   int *d;\n"
         "   double* f;\n"
         "   char* c;\n"
         "   boolean* b;\n"          
         "   switch(type) {\n"
         "     case 'i':\n"
         "       d = (int*) matrix;\n"
         "       for(i = 0; i < size; i++) d[i] = 0;\n"
         "       break;\n"
         "     case 'f':\n"
         "       f = (double*) matrix;\n"
         "       for(i = 0; i < size; i++) f[i] = 0;\n"
         "       break;\n"
         "     case 'c':\n"
         "       c = (char*) matrix;\n"
         "       for(i = 0; i < size; i++) c[i] = 0;\n"
         "       break;\n"
         "     case 'b':\n"
         "       b = (boolean*) matrix;\n"
         "       for(i = 0; i < size; i++) b[i] = 0;\n"
         "       break;\n"
         "     default:\n"
         "       fprintf(stderr, \"bug: tipo nao suportado: %c\\n\", type);\n"
         "       exit(1);\n"
         "   }\n"
         "}\n";
    s << "void imprima(char* format, ...) {\n"
         "   va_list args;\n"
         "   va_start(args, format);\n"
         "   int d;\n"
         "   double f;\n"
         "   int c;\n"
         "   char* s;\n"
         "   int b;\n"
         "   while(*format) {\n"
         "     switch(*format) {\n"
         "       case 'd':\n"
         "         d = va_arg(args, int);\n"
         "         printf(\"%d\", d); \n"
         "         break;\n"
         "       case 'f':\n"
         "         f = va_arg(args, double);\n"
         "         printf(\"%.2f\", f);\n"
         "         break;\n"
         "       case 'c':\n"
         "         c = va_arg(args, int);\n"
         "         printf(\"%c\", c);\n"
         "         break;\n"
         "       case 's':\n"         
         "         s = va_arg(args, char*);\n"
         "         if(!s) {\n"
         "           printf(\"(nulo)\");\n"
         "         } else {\n"
         "           printf(\"%s\", s);\n"
         "         }\n"
         "         break;\n"
         "       case 'b':\n"
         "         b = va_arg(args, int);\n"
         "         if(b) {\n"
         "           printf(\"verdadeiro\");\n"
         "         } else {\n"
         "           printf(\"falso\");\n"
         "         }\n"
         "         break;\n"
         "       default:\n"
         "         fprintf(stderr, \"bug: modificador nao suportado: %c\\n\", *format);\n"
         "         exit(1);\n"
         "     }\n"
         "     format++;\n"
         "   }\n"
         "   va_end(args);\n"
         "   printf(\"\\n\");\n"
         "}\n\n";
    s << "int leia_inteiro__() {\n"
         "   int i = 0;\n"
         "   scanf(\"%d\", &i);\n"
         "   return i;\n"
         "}\n";
    s << "char leia_caractere__() {\n"
         "   char c = 0;\n"
         "   scanf(\"%c\", &c);\n"
         "   return c;\n"
         "}\n";
    s << "double leia_real__() {\n"
         "   double f = 0;\n"
         "   scanf(\"%lf\", &f);\n"
         "   return f;\n"
         "}\n";
    s << "char* leia_literal__() {\n"
         "   char *lit = NULL;\n"
         "   size_t  len = 0;\n"
         "   int read;\n"
         "   if((read = getline(&lit, &len, stdin)) == -1) {\n"
         "     fprintf(stderr, \"Erro ao ler dados da entrada\\n\");\n"
         "     exit(1);\n"
         "   }\n"
         "   lit[strlen(lit)-1] = 0;\n"
         "   collect(lit);\n"
         "   return lit;\n"
         "}\n";
    s << "boolean leia_logico__() {\n"
         "   char* logico;\n"
         "   logico = leia_literal__();\n"
         "   if(strcmp(\"falso\",logico) == 0) {\n"
         "      return FALSE;\n"
         "   } else if(strcmp(\"0\",logico) == 0) {\n"
         "      return FALSE;\n"
         "   }\n"
         "   return TRUE;\n"
         "}\n";
    s << "boolean str_comp__(char* left, char* right) {\n"
         "   if(left == 0) {\n"
         "     if(right == 0) {\n"
         "       return TRUE;\n"
         "     } else {\n"
         "       return FALSE;\n"
         "     }\n"
         "   }\n"
         "   return (strcmp(left, right)==0);\n"
         "}\n";
    s << "int str_strlen__(char* str) {\n"
         "   if(str == 0) {\n"
         "     return 0;\n"
         "   }\n"
         "   return strlen(str);\n"
         "}\n";
    s << "char* return_literal__(char* str) {\n"
         "  char* lit = NULL;\n"
         "  lit = (char*) malloc(sizeof(char)*(str_strlen__(str)+1));\n"
         "  strcpy(lit, str);\n"
         "  collect(lit);\n"
         "  return lit;\n"
         "}\n\n";


    _head << s.str();

    _currentScope = SymbolTable::GlobalScope;
  }

  void setScope(const string& scope) {
    _currentScope = scope;
  }

  void addPrototype(stringstream& str) {
    _head << str.str() << endl; 
  }

  void writeln(const stringstream& s, bool doIndent = true) {
    if(doIndent) _txt << _indent;
    _txt << s.str() << endl;
  }

  void writeln(const string& str, bool doIndent = true) {
    if(doIndent) _txt << _indent;
    _txt << str << endl;
  }

  void write(const string& str, bool doIndent = true) {
    if(doIndent) _txt << _indent;
    _txt << str;
  }

  void write(const stringstream& s, bool doIndent = true) {
    if(doIndent) _txt << _indent;
    _txt << s.str();
  }
  

  void writeInitStms() {
    _txt << _scope_init_stms.str();
    _scope_init_stms.str("");
  }

  void addInitStm(const stringstream& s) {
    _scope_init_stms << "   " << s.str() << "\n";
  }


  string translateFunctionName(const string& id, int type) {
    Symbol s = stable.getSymbol(SymbolTable::GlobalScope, id);
    if(s.isBuiltin) {
      if(s.lexeme == "leia") {
        switch(type) {
          case TIPO_REAL:
            return "leia_real__";
          case TIPO_LITERAL:
            return "leia_literal__";
          case TIPO_CARACTERE:
            return "leia_caractere__";
          case TIPO_LOGICO:
            return "leia_logico__";
          case TIPO_INTEIRO:
          default:
            return "leia_inteiro__";
        }
      } /*else if(s.lexeme == "imprima") {
        return "printf";
      }*/
    }
    return id;
  }

  
  string translateFunctionParams(const string& id, list<pair<int, string> >& params) {
    Symbol s = stable.getSymbol(SymbolTable::GlobalScope, id);
    
    if(s.isBuiltin && (id == "imprima")) {      
      stringstream first_arg;
      first_arg << "\"";
      for(list<pair<int, string> >::iterator it = params.begin(); it != params.end(); ++it) {        
        switch((*it).first) {          
          case TIPO_INTEIRO:   first_arg << "d"; break;
          case TIPO_REAL:      first_arg << "f"; break;
          case TIPO_CARACTERE: first_arg << "c"; break;
          case TIPO_LITERAL:   first_arg << "s"; break;
          case TIPO_LOGICO:    first_arg << "b"; break;
        }
      }
      first_arg << "\"";
      params.push_front(pair<int, string>(TIPO_LITERAL, first_arg .str()));
    }

    stringstream ret;
    string v;
    for(list<pair<int, string> >::iterator it = params.begin(); it != params.end(); ++it) {
      ret << v << (*it).second;
      v = ", ";
    }  
    return ret.str();
  }

  string translateType(int type) {
    string str;
    switch(type) {
      case TIPO_NULO:      str = "void"; break;
      case TIPO_INTEIRO:   str = "int"; break;
      case TIPO_REAL:      str = "double"; break;
      case TIPO_CARACTERE: str = "char"; break;
      case TIPO_LITERAL:   str = "char*"; break;
      case TIPO_LOGICO:    str = "boolean"; break;    
      default:
        cerr << "Erro interno: tipo nao suportado (pt2c::translateType)." << endl;
        exit(1);
    }
    return str;
  }

  
  string translateBinExpr(const production& left, const production& right, int optoken) {
    stringstream ret;
    if((left.expr.first != TIPO_LITERAL) && (right.expr.first != TIPO_LITERAL)) {      
      switch(optoken) {
        case T_IGUAL:
          ret << left.expr.second << "==" << right.expr.second;
          break;
        case T_DIFERENTE:
          ret << left.expr.second << "!=" << right.expr.second;
          break;
        case T_MAIOR:
          ret << left.expr.second << ">" << right.expr.second;
          break;
        case T_MENOR:
          ret << left.expr.second << "<" << right.expr.second;
          break;
        case T_MAIOR_EQ:
          ret << left.expr.second << ">=" << right.expr.second;
          break;
        case T_MENOR_EQ:  
          ret << left.expr.second << "<=" << right.expr.second;
          break;
        default:
          cerr << "Erro interno: op nao suportado (pt2c::translateBinExpr)." << endl;
          exit(1);
      }
      return ret.str();
    }

    switch(optoken) {
      case T_IGUAL:
        ret << "str_comp__(" << left.expr.second << "," << right.expr.second << ")";
        break;
      case T_DIFERENTE:
        ret << "str_comp__(" << left.expr.second << "," << right.expr.second << ")";
      case T_MAIOR:
        ret << "(str_strlen__(" << left.expr.second << ") > str_strlen__(" << right.expr.second << "))";
        break;
      case T_MENOR:
        ret << "(str_strlen__(" << left.expr.second << ") < str_strlen__(" << right.expr.second << "))";
        break;
      case T_MAIOR_EQ:
        ret << "(str_strlen__(" << left.expr.second << ") <= str_strlen__(" << right.expr.second << "))";
        break;
      case T_MENOR_EQ:  
        ret << "(str_strlen__(" << left.expr.second << ") >= str_strlen__(" << right.expr.second << "))";
        break;
      default:
          cerr << "Erro interno: op nao suportado (pt2c::translateBinExpr)." << endl;
          exit(1);
    }
    return ret.str();
  }  
}

/********************************* Producoes **************************************/

algoritmo returns [string str]
  : #(T_KW_ALGORITMO id:T_IDENTIFICADOR) {init(id->getText());}
    (variaveis)? 
    principal 
    (func_decls)*
    {str = _head.str() + _txt.str();}
  ;

variaveis
{
  production p;
  stringstream str;
  stringstream init;
}
  : #(T_KW_VARIAVEIS 
      (
          p=primitivo 
            {
              for(list<string>::iterator it = p.primvars.second.begin(); it != p.primvars.second.end(); ++it) {
                str << translateType(p.primvars.first) << " " << (*it) << " = 0;";
                writeln(str);
                str.str("");
              }
            }

          | p=matriz 
            {
              for(list<string>::iterator itid = p.matrizvars.second.first.begin(); itid !=  p.matrizvars.second.first.end(); ++itid) {
                str << translateType(p.matrizvars.first) << " " << *itid;
                for(list<string>::iterator itdim = p.matrizvars.second.second.begin(); itdim != p.matrizvars.second.second.end(); ++itdim) {
                  str << "[" << *itdim << "]";
                }
                str << ";";
                writeln(str);
      
                init << "matrix_init__(" << *itid << ", ";
                switch(p.matrizvars.first) {
                  case TIPO_INTEIRO:
                    init << "'i', ";break;
                  case TIPO_REAL:
                    init << "'f', ";break;
                  case TIPO_CARACTERE:
                  case TIPO_LITERAL:
                    init << "'c', ";break;      
                  case TIPO_LOGICO:
                    init << "'b', ";break;
                }
      
                int tsize = 1;
                for(list<string>::iterator itdim = p.matrizvars.second.second.begin(); itdim != p.matrizvars.second.second.end(); ++itdim) {
                  tsize = tsize * atoi((*itdim).c_str());
                }
                init << tsize << ");";
                addInitStm(init);
                init.str("");
                str.str("");
              }
            }
      )+
    )
  ;

primitivo returns [production p]
{
  int type;
  stringstream str;
}
  : #(TI_VAR_PRIMITIVE type=tipo_prim {p.primvars.first = type;}
      (
        id:T_IDENTIFICADOR {p.primvars.second.push_back(id->getText());}
      )+
    )
  ;

tipo_prim returns [int t]
  : T_KW_INTEIRO   {t = TIPO_INTEIRO;}
  | T_KW_REAL      {t = TIPO_REAL;}
  | T_KW_CARACTERE {t = TIPO_CARACTERE;}
  | T_KW_LITERAL   {t = TIPO_LITERAL;}
  | T_KW_LOGICO    {t = TIPO_LOGICO;}
  ;

//pair<int,  pair< list<string>, list<string> > > matrizvars;//pair<type, pair<list<ids>,list<dims> > >
matriz returns [production p]
{
  production tp; //pair<int, list<string> > tipo_matriz; //pair<type, list<dimsize> >
}
  : #(TI_VAR_MATRIX tp=tipo_matriz 
        {
          p.matrizvars.first = tp.tipo_matriz.first;
          p.matrizvars.second.second = tp.tipo_matriz.second;
        }
      (id:T_IDENTIFICADOR
        { p.matrizvars.second.first.push_back(id->getText());}
      )+
    )
  ;


tipo_matriz returns [production p]
  : #(T_KW_INTEIROS 
      {p.tipo_matriz.first = TIPO_INTEIRO;}
      (
        s1:T_INT_LIT
        {p.tipo_matriz.second.push_back(s1->getText());}
      )+
    )
  | #(T_KW_REAIS
      {p.tipo_matriz.first = TIPO_REAL;}
      (
        s2:T_INT_LIT
        {p.tipo_matriz.second.push_back(s2->getText());}
      )+
    )
  | #(T_KW_CARACTERES
      {p.tipo_matriz.first = TIPO_CARACTERE;}
      (
        s3:T_INT_LIT
        {p.tipo_matriz.second.push_back(s3->getText());}
      )+
    )
  | #(T_KW_LITERAIS
      {p.tipo_matriz.first = TIPO_LITERAL;}
      (
        s4:T_INT_LIT
        {p.tipo_matriz.second.push_back(s4->getText());}
      )+
    )
  | #(T_KW_LOGICOS
      {p.tipo_matriz.first = TIPO_LOGICO;}
      (
        s5:T_INT_LIT
        {p.tipo_matriz.second.push_back(s5->getText());}
      )+
    )
  ;

principal
  {
    writeln("\nint main(void) {");
    indent();
  }
  : stm_block
    {      
      writeln("cleanup();");
      writeln("return EXIT_SUCCESS;\n}");      
      unindent();
    }
  ;

stm_block
{writeInitStms();}
  : #(T_KW_INICIO (stm)* )
  ;

stm
{production fc;}
  : stm_attr
  | fc=fcall[TIPO_ALL] {writeln(fc.fcall.second + ";");}
  | stm_ret
  | stm_se
  | stm_enquanto
  | stm_para
  ;

stm_attr
{
  production lv; //pair<int, string> lvalue;
  production e; //pair<int, string> expr;

  stringstream str;
  int expecting_type;
}
  : #(T_ATTR lv=lvalue
      {
        expecting_type = lv.lvalue.first;
      }
      e=expr[expecting_type])
    {
      str << lv.lvalue.second << " = " << e.expr.second << ";";
      writeln(str);
    }
  ;

lvalue returns [production p]
{
  stringstream s;  
  production e; //pair<int type, string expr> lvalue;
}
  : #(id:T_IDENTIFICADOR
      {
        p.lvalue.first = stable.getSymbol(_currentScope, id->getText(), true).type.primitiveType();
        s << id->getText();
      }
      (
        e=expr[TIPO_INTEIRO] {s << "[" << e.expr.second <<  "]";}
      )*
    )
    {p.lvalue.second = s.str();}
  ;


//pair< int, string> fcall; //pair<type, text>
fcall[int expct_type] returns [production p] //id, list<dimexpr>
{
  production e;
  list<pair<int, string> > lp;
  Symbol f;
  int type;
  int count = 0;
}
  : #(TI_FCALL id:T_IDENTIFICADOR 
      {
        p.fcall.second = translateFunctionName(id->getText(), expct_type);
        f = stable.getSymbol(SymbolTable::GlobalScope, id->getText()); //so we get the params
        p.fcall.first = f.type.primitiveType();
        type = f.param.paramType(count++);
      }
      (
        e=expr[type]
        {lp.push_back(e.expr);type = f.param.paramType(count++);}
      )*
    )
    {p.fcall.second += "("; p.fcall.second += translateFunctionParams(id->getText(), lp); p.fcall.second += ")";}    
  ;

stm_ret
{
  int expecting_type = stable.getSymbol(SymbolTable::GlobalScope, _currentScope, true).type.primitiveType();
  production e;
  stringstream str;
}
  : #(T_KW_RETORNE (TI_NULL|e=expr[expecting_type]))
    {
      str << "return ";
      if(_currentScopeType == TIPO_LITERAL) {
        str << "return_literal__(" << e.expr.second << ")";
      } else {
        str << e.expr.second;
      }
      str << ";";
      writeln(str);
    }
  ;

stm_se
{
  production e;
  stringstream str;
}
  : #(T_KW_SE e=expr[TIPO_LOGICO]
        {
          str << "if(" << e.expr.second << ") {";
          writeln(str);
          indent();
        }
      (stm)* 
      {
        unindent();
        write("}");        
      }

      ( 
        T_KW_SENAO 
        {
          writeln(" else {", false);
          indent();
        } 

        (stm)*
        {
          unindent();
          writeln("}");
        }
      )?
      {writeln("");}
    )
  ;

stm_enquanto
{
  production e;
  stringstream str;
}
  : #(T_KW_ENQUANTO e=expr[TIPO_LOGICO]
      {
        str << "while(" << e.expr.second << ") {";
        writeln(str);
        indent();
      }
      (stm)*
      {
        unindent();
        writeln("}");
      }
    )
  ;

stm_para
{
  bool haspasso = false;
  production var, de, ate, ps;
  stringstream str;
}
  : #(T_KW_PARA var=lvalue de=expr[TIPO_INTEIRO] ate=expr[TIPO_INTEIRO] (ps=passo {haspasso=true;})?
      {
        if(!haspasso) {
            str  << "for(" <<    var.lvalue.second << "=" << de.expr.second << ";" 
                              << var.lvalue.second << "<=" << ate.expr.second << ";" 
                              << var.lvalue.second << "+=" << 1 << ") {";
        } else {
          if(ps.passo.first) {//crescente
            str  << "for(" << var.lvalue.second << "=" << de.expr.second << ";" 
                              << var.lvalue.second << "<=" << ate.expr.second << ";" 
                              << var.lvalue.second << "+=" << ps.passo.second << ") {";            
          } else { //decrescente
            str  << "for(" << var.lvalue.second << "=" << de.expr.second << ";" 
                              << var.lvalue.second << ">=" << ate.expr.second << ";" 
                              << var.lvalue.second << "-=" << ps.passo.second << ") {";
          }
        }
        writeln(str);
        indent();
      }
    (stm)*
    {
      unindent();
      writeln("}");
      str.str("");
      str << var.lvalue.second << " = " << ate.expr.second << ";";
      writeln(str);
    }
    )
  ;

passo returns [production p]
{p.passo.first=true;}
  : #(T_KW_PASSO (
          T_MAIS  {p.passo.first=true;} //crescente
        | T_MENOS {p.passo.first=false;} //decrescente
        )? 
      i:T_INT_LIT {p.passo.second = i->getText();}
    )
  ;

expr[int expecting_type] returns [production p]
{
  production left,right;
}
  : #(T_BIT_OU    left=expr[expecting_type] right=expr[expecting_type]) {p.expr.second=left.expr.second;p.expr.second+="|";p.expr.second+=right.expr.second;p.expr.first=#expr->getEvalType();}  
  | #(T_BIT_XOU   left=expr[expecting_type] right=expr[expecting_type]) {p.expr.second=left.expr.second;p.expr.second+="^";p.expr.second+=right.expr.second;p.expr.first=#expr->getEvalType();}
  | #(T_BIT_KW_E  left=expr[expecting_type] right=expr[expecting_type]) {p.expr.second=left.expr.second;p.expr.second+="&";p.expr.second+=right.expr.second;p.expr.first=#expr->getEvalType();}
  | #(T_BIT_NOT   left=expr[expecting_type] right=expr[expecting_type]) {p.expr.second=left.expr.second;p.expr.second+="~";p.expr.second+=right.expr.second;p.expr.first=#expr->getEvalType();}
//  | #(T_IGUAL     left=expr[expecting_type] right=expr[expecting_type]) {p.expr.second=left.expr.second;p.expr.second+="==";p.expr.second+=right.expr.second;p.expr.first=#expr->getEvalType();}
  | #(T_IGUAL    left=expr[expecting_type] right=expr[expecting_type]) {p.expr.second=translateBinExpr(left,right,T_IGUAL);p.expr.first=#expr->getEvalType();}
  //| #(T_DIFERENTE left=expr[expecting_type] right=expr[expecting_type]) {p.expr.second=left.expr.second;p.expr.second+="!=";p.expr.second+=right.expr.second;p.expr.first=#expr->getEvalType();}
  | #(T_DIFERENTE left=expr[expecting_type] right=expr[expecting_type]) {p.expr.second=translateBinExpr(left,right,T_DIFERENTE);p.expr.first=#expr->getEvalType();}
  //| #(T_MAIOR     left=expr[expecting_type] right=expr[expecting_type]) {p.expr.second=left.expr.second;p.expr.second+=">";p.expr.second+=right.expr.second;p.expr.first=#expr->getEvalType();}
  | #(T_MAIOR     left=expr[expecting_type] right=expr[expecting_type]) {p.expr.second=p.expr.second=translateBinExpr(left,right,T_MAIOR);p.expr.first=#expr->getEvalType();}
  //| #(T_MENOR     left=expr[expecting_type] right=expr[expecting_type]) {p.expr.second=left.expr.second;p.expr.second+="<";p.expr.second+=right.expr.second;p.expr.first=#expr->getEvalType();}
  | #(T_MENOR     left=expr[expecting_type] right=expr[expecting_type]) {p.expr.second=p.expr.second=translateBinExpr(left,right,T_MENOR);p.expr.first=#expr->getEvalType();}
  //| #(T_MAIOR_EQ  left=expr[expecting_type] right=expr[expecting_type]) {p.expr.second=left.expr.second;p.expr.second+=">=";p.expr.second+=right.expr.second;p.expr.first=#expr->getEvalType();}
  | #(T_MAIOR_EQ  left=expr[expecting_type] right=expr[expecting_type]) {p.expr.second=p.expr.second=translateBinExpr(left,right,T_MAIOR_EQ);p.expr.first=#expr->getEvalType();}
  //| #(T_MENOR_EQ  left=expr[expecting_type] right=expr[expecting_type]) {p.expr.second=left.expr.second;p.expr.second+="<=";p.expr.second+=right.expr.second;p.expr.first=#expr->getEvalType();}
  | #(T_MENOR_EQ  left=expr[expecting_type] right=expr[expecting_type]) {p.expr.second=p.expr.second=translateBinExpr(left,right,T_MENOR_EQ);p.expr.first=#expr->getEvalType();}
  | #(T_MAIS      left=expr[expecting_type] right=expr[expecting_type]) {p.expr.second=left.expr.second;p.expr.second+="+";p.expr.second+=right.expr.second;p.expr.first=#expr->getEvalType();}
  | #(T_MENOS     left=expr[expecting_type] right=expr[expecting_type]) {p.expr.second=left.expr.second;p.expr.second+="-";p.expr.second+=right.expr.second;p.expr.first=#expr->getEvalType();}
  | #(T_DIV       left=expr[expecting_type] right=expr[expecting_type]) {p.expr.second=left.expr.second;p.expr.second+="/";p.expr.second+=right.expr.second;p.expr.first=#expr->getEvalType();}
  | #(T_MULTIP    left=expr[expecting_type] right=expr[expecting_type]) {p.expr.second=left.expr.second;p.expr.second+="*";p.expr.second+=right.expr.second;p.expr.first=#expr->getEvalType();}
  | #(T_MOD       left=expr[expecting_type] right=expr[expecting_type]) {p.expr.second=left.expr.second;p.expr.second+="%";p.expr.second+=right.expr.second;p.expr.first=#expr->getEvalType();}
  | #(TI_UN_NEG  right=element[expecting_type]) {p.expr.second="-";p.expr.second+=right.expr.second;p.expr.first=#expr->getEvalType();}
  | #(TI_UN_POS  right=element[expecting_type]) {p.expr.second="+";p.expr.second+=right.expr.second;p.expr.first=#expr->getEvalType();}
  | #(TI_UN_NOT  right=element[expecting_type]) {p.expr.second="!";p.expr.second+=right.expr.second;p.expr.first=#expr->getEvalType();}
  | #(TI_UN_BNOT right=element[expecting_type]) {p.expr.second="~";p.expr.second+=right.expr.second;p.expr.first=#expr->getEvalType();}
  | p=element[expecting_type]
  ;


element[int expecting_type] returns [production p]
{
  production other;
  string str;
}
  : other=literal             {p.expr.first = other.expr.first; p.expr.second = other.expr.second;}
  | other=fcall[expecting_type]   {p.expr = other.fcall;}
  | other=lvalue              {p.expr = other.lvalue;}
  | #(TI_PARENTHESIS other=expr[expecting_type])  {p.expr = other.expr;}
  ;

literal returns [production p]
  : s:T_STRING_LIT        
    {
      p.expr.first=TIPO_LITERAL;   
      if(s->getText().length() == 0) {
        p.expr.second = "0";
      } else {
        p.expr.second = "\""; 
        p.expr.second += s->getText();
        p.expr.second += "\"";
      }
    }
  | i:T_INT_LIT           {p.expr.first=TIPO_INTEIRO;   p.expr.second = i->getText();}
  | r:T_REAL_LIT          {p.expr.first=TIPO_REAL;      p.expr.second = r->getText();}
  | c:T_CARAC_LIT         
    {
      if(c->getText().length() > 0) {
        p.expr.first=TIPO_CARACTERE; 
        p.expr.second = "'"; 
        p.expr.second += c->getText();
        p.expr.second += "'";
      } else {
        p.expr.first=TIPO_CARACTERE; 
        p.expr.second = "0";
      }
    }
  | v:T_KW_VERDADEIRO     {p.expr.first=TIPO_LOGICO;    p.expr.second = "TRUE";}
  | f:T_KW_FALSO          {p.expr.first=TIPO_LOGICO;    p.expr.second = "FALSE";}
  ;

func_decls
{
  production prim;
  production mat;
  stringstream str;
  stringstream cpy;
  stringstream decl;
  string comma;
}
  : #(id:T_IDENTIFICADOR   
      {
        setScope(id->getText());
        //nota: nao estamos usando a producao "ret_type" para saber o tipo de retorno.
        //      Procuramos diretamente na tabela de simbolos. (conveniencia)
        _currentScopeType = stable.getSymbol(SymbolTable::GlobalScope, id->getText(), true).type.primitiveType();
        str << translateType(_currentScopeType);
        str << " " << id->getText() << "(";
      }

      (
          prim=primitivo
            {              
              for(list<string>::iterator it = prim.primvars.second.begin(); it != prim.primvars.second.end(); ++it) {
                str << comma << translateType(prim.primvars.first) << " " << (*it);
                comma = ", ";
              }
            }
        | mat=matriz
            {
              stringstream s;
              for(list<string>::iterator itid = mat.matrizvars.second.first.begin(); itid !=  mat.matrizvars.second.first.end(); ++itid) {
                s << comma << translateType(mat.matrizvars.first) << " " << *itid << "__";
                decl << translateType(mat.matrizvars.first) << " " << *itid;
        
                comma = ",";
                for(list<string>::iterator itdim = mat.matrizvars.second.second.begin(); itdim != mat.matrizvars.second.second.end(); ++itdim) {
                  s << "[" << *itdim << "]";
                  decl << "[" << *itdim << "]";
                }                
        
                decl << ";";
                addInitStm(decl);
                decl.str("");

                cpy << "matrix_cpy__(" << *itid << "__, " << *itid << ", ";
                switch(mat.matrizvars.first) {
                  case TIPO_INTEIRO:
                    cpy << "'i', ";break;
                  case TIPO_REAL:
                    cpy << "'f', ";break;
                  case TIPO_CARACTERE:
                  case TIPO_LITERAL:
                    cpy << "'c', ";break;      
                  case TIPO_LOGICO:
                    cpy << "'b', ";break;
                }
      
                int tsize = 1;
                for(list<string>::iterator itdim = mat.matrizvars.second.second.begin(); itdim != mat.matrizvars.second.second.end(); ++itdim) {
                  tsize = tsize * atoi((*itdim).c_str());
                }
                cpy << tsize << ");";
                addInitStm(cpy);        
                cpy.str("");
                str << s.str();
                s.str("");
              }
            }
      )*

      //(ret_type)?

      {
        if((_t != antlr::nullAST) && (_t->getType() == TI_FRETURN)) {
          _t = _t->getNextSibling();
        }

        str << ")";
        stringstream prototype;
        prototype << str.str() << ";";
        addPrototype(prototype);

        str << " {";
        writeln(str);
        indent();
      }

      (variaveis)?
      stm_block
      {
        //for�a retorno, se o usuario esqueceu:
//         if(fret != TIPO_NULO) {
//           writeln("return -1;");
//         }

        unindent();
        writeln("}");
        setScope(SymbolTable::GlobalScope);
        _currentScopeType = -1;
      }
    )
  ;

// ret_type //returns [int rettype]
//   : #(TI_FRETURN
// //       (
//           /*rettype=*/tipo_prim
// //         | | #(TI_VAR_MATRIX tipo_matriz)
// //       )
//     )
// //  | /*empty {str = "void";} */
//   ;


// arg_primitivo returns [production p]
//   : #(TI_VAR_PRIMITIVE tipo_prim 
//       (id:T_IDENTIFICADOR)+ 
//     )
//   ;

// arg_matriz
//   : #(TI_VAR_MATRIX tipo_matriz 
//       (id:T_IDENTIFICADOR)+
//       )
//   ;
