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
//   #include <map>
//   #include <list>
  using namespace std;
}

options {
  language="Cpp";
}

class X86Walker extends TreeParser;
options {
  importVocab=Portugol;  // use vocab generated by lexer
  ASTLabelType="RefPortugolAST";
  noConstructors=true;
  genHashLines=false;//no #line
}

{
  public:
  X86Walker(SymbolTable& st) 
    : stable(st) { }

  private:

  void init(string name) {
    head << "; algoritmo: " << name << endl;
    data << "section .data" << endl;

    bss << "section .bss" << endl;
    bss << "__buffer resb 1024" << endl;


    txt << "section .text" << endl;
    txt << "global _start" << endl;

    txt << "__strlen:\n"
           "mov ebx, 0\n"
           ".do:\n"
           "cmp [eax+ebx], byte 0\n"
           "jz  .break\n"
           "inc ebx\n"
           "jnz .do\n"
           ".break\n"
           "ret\n\n";

    txt << "__imprima_literal:\n"
           "push eax\n"
           "push ebx\n"
           "push ecx\n"
           "push edx\n"
           "call __strlen\n"
           "mov ecx, eax\n"
           "mov edx, ebx\n"
           "inc edx\n"
           "mov eax, 4\n"
           "mov ebx, 1\n"            
           "int 80h\n"
           "pop edx\n"
           "pop ecx\n"
           "pop ebx\n"
           "pop eax\n"
           "ret\n\n";

    txt << "__imprima_caractere:\n"
           "push eax\n"
           "push ebx\n"
           "push ecx\n"
           "push edx\n"
	         "segment .data\n"
	         ".carac db 0\n"
	         "segment .text\n"
           "mov [.carac], eax\n"
	         "mov ecx, .carac\n"
 	         "mov edx, 1\n"
	         "mov eax, 4\n"
           "mov ebx, 1\n"
 	         "int 80h\n"
           "pop edx\n"
           "pop ecx\n"
           "pop ebx\n"
           "pop eax\n"
	         "ret\n\n";

    txt << "__imprima_inteiro:\n"
           "push eax\n"
           "push ebx\n"
           "push ecx\n"
           "push edx\n"
           "call __itoa\n"
           "mov eax, __buffer\n"
           "call __imprima_literal\n"
           "pop edx\n"
           "pop ecx\n"
           "pop ebx\n"
           "pop eax\n"
           "ret\n\n";

    txt << "__itoa:\n"
           "push eax\n"
           "push ebx\n"
           "push ecx\n"
           "push edx\n"
           "mov ecx, 0\n"
           "mov ebx, 10\n"
           ".trans:\n"
           "mov edx, 0\n"
           "idiv ebx\n"
           "add edx, BYTE 48\n"
           "push edx\n"
           "inc ecx\n"            
           "cmp eax, 0\n"
           "jz  .btrans\n"
           "jnz .trans\n"
           ".btrans:\n"
           "mov ebx, 0\n"
           ".reorder:\n"
           "pop edx\n"
           "mov [ebx+__buffer], edx\n"
           "inc ebx;\n"
           "dec ecx\n"
           "cmp ecx, 0\n"
           "jnz .reorder\n"
           "pop edx\n"
           "pop ecx\n"
           "pop ebx\n"
           "pop eax\n"
           "ret\n\n";

    txt << "__exit_success:\n"
           "mov eax,1\n"
           "mov ebx,0\n"
           "int 80h\n\n";
  
    _currentScope = "@global";
  }

  void declarePrimitive(bool isGlobal, int type, string name) {
    if(isGlobal) {
      switch(type) {
        case TIPO_INTEIRO:
          data << name << " dd 0" << endl;
          break;
        case TIPO_REAL:
          data << name << " dd 0" << endl;
          break;
        case TIPO_CARACTERE:
          data << name << " dd 0" << endl;
          break;
        case TIPO_LITERAL:
          data << name << " db 0" << endl;
          break;
        case TIPO_LOGICO:
          data << name << " dd 0" << endl;
          break;
        default:
          cerr << "Erro interno: tipo nao suportado (x86::declarePrimitive)." << endl;
          exit(1);
      }    
    } else {
      //TODO
    }
  }

  void declareMatrix(bool isGlobal, int type, string name, list<string> dims) {
    int size = 1;
    for(list<string>::iterator it = dims.begin(); it != dims.end(); it++) {
      size *= atoi((*it).c_str());
    }

    if(isGlobal) {
      switch(type) {
        case TIPO_INTEIRO:
          data << name << " times " << size << " dd 0" << endl;
          break;
        case TIPO_REAL:
          data << name << " times " << size << " dd 0" << endl;
          break;
        case TIPO_CARACTERE:
          data << name << " times " << size << " dd 0" << endl;
          break;
        case TIPO_LITERAL:
          data << name << " times " << size << " db 0" << endl;
          break;
        case TIPO_LOGICO:
          data << name << " times " << size << " dd 0" << endl;
          break;
        default:
          cerr << "Erro interno: tipo nao suportado (x86::declareMatrix)." << endl;
          exit(1);
      }    
    } else {
      //TODO
    }
  }

  string createLabel(string tmpl) {
    static int c = 0;
    stringstream s;
    s << "___" << tmpl << "_" << c;
    c++;
    return s.str();
  }

  string insertString(string str) {
    string lb = createLabel("str");
    data << lb << " db '" << str << "',0" << endl;
    return lb;
  }

  string translateFuncLeia(const string& id, int type) {
    switch(type) {
      case TIPO_REAL:
        return "__leia_real";
      case TIPO_LITERAL:
        return "__leia_literal";
      case TIPO_CARACTERE:
        return "__leia_caractere";
      case TIPO_LOGICO:
        return "__leia_logico";
      case TIPO_INTEIRO:
      default:
        return "__leia_inteiro";
    }
  }

  string translateFuncImprima(const string& id, int type) {
    switch(type) {
      case TIPO_REAL:
        return "__imprima_real";
      case TIPO_LITERAL:
        return "__imprima_literal";
      case TIPO_CARACTERE:
        return "__imprima_caractere";
      case TIPO_LOGICO:
        return "__imprima_logico";
      case TIPO_INTEIRO:
        return "__imprima_inteiro";
      default:
        cerr << "Erro interno: tipo nao suportado (x86::translateFuncImprima)." << endl;
        exit(1);
    }
  }
  
  void writeln(string str) {
    txt << str << endl;
  }

  void writeFooter() {
    txt << "call __exit_success\n";
  }

  stringstream bss;
  stringstream data;
  stringstream head;
  stringstream txt;

  string _currentScope;

  SymbolTable& stable;
}

/********************************* Producoes **************************************/

algoritmo returns [string str]
  : #(T_KW_ALGORITMO id:T_IDENTIFICADOR) {init(id->getText());}
    (variaveis[true])? 
     principal
//     (func_decls)*

  {
    str = head.str(); 
    str += data.str(); 
    str += bss.str(); 
    str += txt.str();
  }
  ;

variaveis[bool isGlobal]
  : #(T_KW_VARIAVEIS (primitivo[isGlobal] | matriz[isGlobal])+ )
  ;

primitivo[bool isGlobal]
{
  int type;
  stringstream str;
}
  : #(TI_VAR_PRIMITIVE type=tipo_prim
      (
        id:T_IDENTIFICADOR
        {declarePrimitive(isGlobal, type, id->getText());}
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

matriz[bool isGlobal]
{
  pair<int, list<string> > tp;
}
  : #(TI_VAR_MATRIX tp=tipo_matriz 
      (
        id:T_IDENTIFICADOR
        {declareMatrix(isGlobal, tp.first, id->getText(), tp.second);}
      )+
    )
  ;


tipo_matriz returns [pair<int, list<string> > p] //pair<type, list<dimsize> >
  : #(T_KW_INTEIROS 
      {p.first = TIPO_INTEIRO;}
      (
        s1:T_INT_LIT
        {p.second.push_back(s1->getText());}
      )+
    )
  | #(T_KW_REAIS
      {p.first = TIPO_REAL;}
      (
        s2:T_INT_LIT
        {p.second.push_back(s2->getText());}
      )+
    )
  | #(T_KW_CARACTERES
      {p.first = TIPO_CARACTERE;}
      (
        s3:T_INT_LIT
        {p.second.push_back(s3->getText());}
      )+
    )
  | #(T_KW_LITERAIS
      {p.first = TIPO_LITERAL;}
      (
        s4:T_INT_LIT
        {p.second.push_back(s4->getText());}
      )+
    )
  | #(T_KW_LOGICOS
      {p.first = TIPO_LOGICO;}
      (
        s5:T_INT_LIT
        {p.second.push_back(s5->getText());}
      )+
    )
  ;

principal
{writeln("_start:");}
  : stm_block
{writeFooter();}
  ;

stm_block
  : #(T_KW_INICIO (stm)* )
  ;

stm
{int t;}
  : stm_attr
  | t=fcall[TIPO_ALL]
//   | stm_ret
  | stm_se
//   | stm_enquanto
//   | stm_para
  ;

stm_attr
{
  pair<int, string> lv;
  int expecting_type;
  stringstream s;

  writeln("; atribuicao");
}
  : #(T_ATTR lv=lvalue
      {
        expecting_type = stable.getSymbol(_currentScope, lv.second, true).type.primitiveType();

        writeln("push ebx");//push dimension offset if it is matrix
      }

      expr[expecting_type]
		)

    {
      writeln("pop ebx");//pops the dimension offset if it is matrix
      s << "mov [" << lv.second << " + ebx], eax";
      writeln(s.str());
    }
  ;

lvalue returns [pair<int, string> p]
{
  list<int> dims;
  list<int>::iterator it = dims.begin();

  unsigned int c = 1;
  stringstream s;

  Symbol symb;
}
  : #(id:T_IDENTIFICADOR
      {
        symb = stable.getSymbol(_currentScope, id->getText(), true);
        p.first = symb.type.primitiveType();
        p.second = id->getText();
        
        dims = symb.type.dimensions();

        if(dims.size() > 0) {
          writeln("push eax");
          writeln("mov ebx, 1");
          writeln("push ebx");
        } else {
          writeln("mov ebx, 0");
        }
      }

      (
        expr[TIPO_INTEIRO]
        {
          writeln("pop ebx");

          if(c == dims.size()) {
            if(dims.size() == 1) {
              writeln("mov ebx, eax");
            } else {
              writeln("add ebx, eax");
            }
          } else {
            s << "mul ebx, " << *it;
            writeln(s.str());
          }

          writeln("push ebx");
          c++;
          it++;
        }
      )*

      {
        if(dims.size() > 0) {
          writeln("pop ebx");
          writeln("pop eax");
        }
      }
    )
  ;

fcall[int expct_type] returns [int type]
{
  Symbol f;
  int count = 0;

  string fname, fimp;
  stringstream s;
  int etype;
  int ptype;
}
  : #(TI_FCALL id:T_IDENTIFICADOR 
      {
        f = stable.getSymbol(SymbolTable::GlobalScope, id->getText()); //so we get the params        
        type = f.type.primitiveType();
        if(f.lexeme == "leia") {
          fname = translateFuncLeia(id->getText(), expct_type);
        } else {
          fname = f.lexeme;
        }
        ptype = f.param.paramType(count++);
      }
      (
        etype=expr[ptype]
        {
          if(fname == "imprima") {
            fimp = translateFuncImprima(id->getText(), etype);
  
            s << "call " << fimp;
            writeln(s.str());
            s.str("");
          } else {
            writeln("push eax"); //push params
            ptype = f.param.paramType(count++);
          }
        }
      )*
    )
    {
      if(fname == "imprima") {
        writeln("mov eax, 10"); //\n
        writeln("call __imprima_caractere");
      } else {
        s << "call " << fname;
        writeln(s.str());
      }
    }
  ;


/*
stm_ret
{
  int expecting_type = stable.getSymbol(SymbolTable::GlobalScope, _currentScope, true).type.primitiveType();
  production e;
  stringstream str;
}
  : #(T_KW_RETORNE (TI_NULL|e=expr[expecting_type]))
  ;

*/
stm_se
{
  stringstream s;
  string lbnext, lbfim;

  lbnext = createLabel("next_se");
  lbfim = createLabel("fim_se");

  bool hasElse = false;

  writeln("; se: expressao");
}
  : #(T_KW_SE expr[TIPO_LOGICO]

    {
      writeln("; se: resultado");

      writeln("cmp eax, 0");
      s << "jne " << lbnext;
      writeln(s.str());

      writeln("; se: caso verdadeiro:");
    }

      (stm)*
    (
        T_KW_SENAO

      {
        hasElse = true;

        s.str("");
        s << "jmp " << lbfim;
        writeln(s.str());

        writeln("; se: caso falso:");

        s.str("");
        s << lbnext << ":";
        writeln(s.str());
      }
        (stm)*
      )?
    )

    {
      writeln("; se: fim:");

      s.str("");
      if(hasElse) {
        s << lbfim << ":";        
      } else {
        s << lbnext << ":";
      }
      writeln(s.str());
    }
  ;

/*
stm_enquanto
{
  production e;
  stringstream str;
}
  : #(T_KW_ENQUANTO e=expr[TIPO_LOGICO]
      (stm)*
    )
  ;

stm_para
{
  bool haspasso = false;
  production de,ate, ps;
  stringstream str;
}
  : #(T_KW_PARA id:T_IDENTIFICADOR de=expr[TIPO_INTEIRO] ate=expr[TIPO_INTEIRO] (ps=passo {haspasso=true;})?
      (stm)*
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

*/

expr[int expecting_type, string reg = "eax"] returns [int etype]
{
  stringstream s;
}
  : #(T_BIT_OU    etype=expr[expecting_type] etype=expr[expecting_type])
  | #(T_BIT_XOU   etype=expr[expecting_type] etype=expr[expecting_type])
  | #(T_BIT_KW_E  etype=expr[expecting_type] etype=expr[expecting_type])
  | #(T_BIT_NOT   etype=expr[expecting_type] etype=expr[expecting_type])
  | #(T_IGUAL     etype=expr[expecting_type] etype=expr[expecting_type, "ebx"]) {writeln("sub eax, ebx");}
  | #(T_DIFERENTE etype=expr[expecting_type] etype=expr[expecting_type])
  | #(T_MAIOR     etype=expr[expecting_type] etype=expr[expecting_type])
  | #(T_MENOR     etype=expr[expecting_type] etype=expr[expecting_type])
  | #(T_MAIOR_EQ  etype=expr[expecting_type] etype=expr[expecting_type])
  | #(T_MENOR_EQ  etype=expr[expecting_type] etype=expr[expecting_type])
  | #(T_MAIS      etype=expr[expecting_type] etype=expr[expecting_type])
  | #(T_MENOS     etype=expr[expecting_type] etype=expr[expecting_type])
  | #(T_DIV       etype=expr[expecting_type] etype=expr[expecting_type])
  | #(T_MULTIP    etype=expr[expecting_type] etype=expr[expecting_type])
  | #(T_MOD       etype=expr[expecting_type] etype=expr[expecting_type])
  | #(TI_UN_NEG   etype=element[expecting_type, reg])
  | #(TI_UN_POS   etype=element[expecting_type, reg])
  | #(TI_UN_NOT   etype=element[expecting_type, reg])
  | #(TI_UN_BNOT  etype=element[expecting_type, reg])
  | etype=element[expecting_type, reg]
  ;

element[int expecting_type, string reg] returns [int etype]
{
  stringstream s;
  string str;
  pair<int, string> p;
}
  : p=literal {s << "mov " << reg << ", " << p.second; writeln(s.str());etype = p.first;}
  | etype=fcall[expecting_type]
  | p=lvalue  {s << "mov " << reg << ", [" << p.second << " + ebx]"; writeln(s.str());etype = p.first;}
  | #(TI_PARENTHESIS etype=expr[expecting_type, reg])
  ;

literal returns [pair<int, string> p]
{stringstream ss;}
  : s:T_STRING_LIT        {p.second = insertString(s->getText());p.first = TIPO_LITERAL;}
  | i:T_INT_LIT           {p.second = i->getText();p.first = TIPO_INTEIRO;}
  | r:T_REAL_LIT          {p.second = r->getText();p.first = TIPO_REAL;}
  | c:T_CARAC_LIT         {ss << (int) c->getText().c_str()[0]; p.second = ss.str();p.first = TIPO_CARACTERE;}
  | v:T_KW_VERDADEIRO     {p.second = "1";p.first = TIPO_LOGICO;}
  | f:T_KW_FALSO          {p.second = "0";p.first = TIPO_LOGICO;}
  ;


/*
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

      (variaveis[false])?
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
  ;*/

