/***************************************************************************
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
 ***************************************************************************/

#include "X86.hpp"
#include "Display.hpp"

#include <stdlib.h>

X86SubProgram::X86SubProgram() {
}

X86SubProgram::X86SubProgram(const X86SubProgram& other) {
  _name = other._name;
  _params = other._params;
  _locals = other._locals;
  _txt << other._txt.str();
}

X86SubProgram::~X86SubProgram() {
}

void X86SubProgram::writeTEXT(const string& str) {
  _txt << str << endl;
}

void X86SubProgram::setName(const string& name) {
  _name = name;
}

string X86SubProgram::name() {
  return _name;
}

void X86SubProgram::declareLocal(const string& name, int type) {
}

void X86SubProgram::declareParam(const string& name, int type) {
/*
    stringstream s;
    if(type == TIPO_LITERAL) {
      s << "%define _p_" << name << "ebp+" << _param_ebp_offset;
      writeln(s.str());
      s.str("");
      s << "%define " << name << "ebp-" << _local_ebp_offset;
      writeln(s.str());
      s.str("");
      _local_ebp_offset+=4;

      s << "addarg dword [_p_" << name << "]";
      writeln(s.str());
      s.str("");
      s << "addarg dword [" << name << "]";
      writeln(s.str());
      s.str("");
      s << "call __strcpy";
      writeln(s.str());
      s.str("");
      s << "clargs 2";
      writeln(s.str());        
    } else {
      s << "%define " << name << "ebp+" << _param_ebp_offset;
      writeln(s.str());        
    }
    _param_ebp_offset+= 4;
*/
}

string X86SubProgram::source() {
  stringstream s;
  s << name() << ":" << endl;
  s << _txt.str();
 
  return s.str();
}


////////--------------------------------------------------------


X86::X86(SymbolTable& st) 
 : _stable(st) {

}

X86::~X86() {
}

void X86::init(const string& name) {

    _head << "; algoritmo: " << name << "\n\n";

    #include <asm_tmpl.h>

    _bss << "section .bss\n"
           "    __mem    resb  __MEMORY_SIZE\n\n";

    _data << "section .data\n"
            "              _data_no equ $\n"
            "    __mem_ptr         dd 0\n"
            "    __aux             dd 0\n"
            "    __str_true        db 'verdadeiro',0\n"
            "    __str_false       db 'falso',0\n"
            "    __str_no_mem_left db 'N�o foi poss�vel alocar mem�ria.',0\n\n";


  createScope(SymbolTable::GlobalScope);
}

void X86::writeBSS(const string& str) {
  _bss << str << endl;
}

void X86::writeDATA(const string& str) {
  _data << str << endl;
}

void X86::writeTEXT(const string& str) {
  _subprograms[_currentScope].writeTEXT(str);;

}

void X86::createScope(const string& scope) {
  _currentScope = scope;
  if(scope == SymbolTable::GlobalScope) {
    _subprograms[scope].setName("_start");    
  } else {
    _subprograms[scope].setName(scope);
  }
}

string X86::currentScope() {
  return _currentScope;
}

void X86::writeExit() {
  writeTEXT("exit 0");
}

void X86::declarePrimitive(int decl_type, const string& name, int type) {
  stringstream s;
  if(decl_type == VAR_GLOBAL) {
    //all sizes have 32 bits (double word)
    switch(type) {
      case TIPO_INTEIRO:
      case TIPO_REAL:
      case TIPO_CARACTERE:
      case TIPO_LITERAL:
      case TIPO_LOGICO:
        s << name << " dd 0";
        writeDATA(s.str());
        break;
      default:
        Display::self()->showError("Erro interno: tipo nao suportado (x86::declarePrimitive).");
        exit(1);
    }
  } else if(decl_type == VAR_PARAM) {
    //TODO
  } else if(decl_type == VAR_LOCAL) {
    //TODO
  } else {
    //error
  }
}

void X86::declareMatrix(int decl_type, int type, string name, list<string> dims) {
  int size = 1;
  for(list<string>::iterator it = dims.begin(); it != dims.end(); it++) {
    size *= atoi((*it).c_str());
  }

  if(decl_type == VAR_GLOBAL) {
    declarePrimitive(VAR_GLOBAL, name, TIPO_INTEIRO);//*TIPO_INTEIRO (pointer)
    stringstream s;
    s << "addarg " << size << " * 4";
    writeTEXT(s.str()); 
    s.str("");
    writeTEXT("call __malloc"); 
    writeTEXT("clargs 1"); 
    s << "mov [" << name << "], eax";
    writeTEXT(s.str());
    s.str("");
    s << "addarg dword [" << name << "]";
    writeTEXT(s.str());
    s.str("");
    s << "addarg " << size << "*4";
    writeTEXT(s.str());
    writeTEXT("call matrix_init__");
    writeTEXT("clargs 2");
  } else if(decl_type == VAR_PARAM) {
    //TODO
  } else if(decl_type == VAR_LOCAL) {
    //TODO
  } else {
    //error
  }
}


string X86::addGlobalLiteral(string str) {
  stringstream s;
  string lb = createLabel(false, "str");
  s << lb << " db '" << str << "',0" << endl;
  writeDATA(s.str());
  return lb;
}

string X86::translateFuncLeia(const string& id, int type) {
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

string X86::translateFuncImprima(const string& id, int type) {
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
      Display::self()->showError("Erro interno: tipo nao suportado (x86::translateFuncImprima).");
      exit(1);
  }
}



string X86::createLabel(bool local, string tmpl) {
  static int c = 0;
  stringstream s;
  if(local) {
    s << ".___" << tmpl << "_" << c;
  } else {
    s << "___" << tmpl << "_" << c;
  }
  c++;
  return s.str();
}


string X86::source() {
  stringstream str;

  //.data footer
  writeDATA("datasize   equ     $ - _data_no");

  str << _head.str()
      << _bss.str()
      << _data.str();

  //.text header
  str << "section .text" << endl;
  str << "_start_no equ $" << endl;

  for(map<string, X86SubProgram>::iterator it = _subprograms.begin(); it != _subprograms.end(); ++it) {
    str << it->second.source();
  }

  str  << _lib.str();

  return str.str();
}


void X86::writeAttribution(int etype, int expecting_type, pair<pair<int, bool>, string>& lv) {
  writeTEXT("pop eax");
  writeTEXT("pop ecx");

  //casts
  if((etype != TIPO_REAL) && (expecting_type == TIPO_REAL)) {
    //int to float
    writeTEXT("mov dword [__aux], eax");
    writeTEXT("fild dword [__aux]");
    writeTEXT("fstp dword [__aux]");
    writeTEXT("mov eax, dword [__aux]");
  } else if((etype == TIPO_REAL) && (expecting_type != TIPO_REAL)) {
    writeTEXT("mov dword [__aux], eax");
    writeTEXT("fld dword [__aux]");
    writeTEXT("fistp dword [__aux]");
    writeTEXT("mov eax, dword [__aux]");
  }
  stringstream s;
  if(lv.first.second) { //if is primitive
    s << "mov edx, dword " << lv.second;
  } else {
    s << "mov edx, dword [" << lv.second << "]";
  }
  writeTEXT(s.str());
  s.str("");
  s << "lea edx, [edx+ecx*4]";
  writeTEXT(s.str());
  s.str("");
  s << "mov [edx], eax";
  writeTEXT(s.str());
}


void X86::writeOuExpr() {
  writeTEXT("pop ebx");
  writeTEXT("pop eax");

  writeTEXT("cmp eax, 0");
  writeTEXT("setne al");
  writeTEXT("and eax, 0xff");
  writeTEXT("cmp ebx, 0");
  writeTEXT("setne bl");
  writeTEXT("and ebx, 0xff");
  writeTEXT("or al, bl");

  writeTEXT("push eax");
}

void X86::writeEExpr() {
  writeTEXT("pop ebx");
  writeTEXT("pop eax");

  writeTEXT("cmp eax, 0");        
  writeTEXT("setne al");
  writeTEXT("and eax, 0xff");
  writeTEXT("cmp ebx, 0");
  writeTEXT("setne bl");
  writeTEXT("and ebx, 0xff");
  writeTEXT("and al, bl");

  writeTEXT("push eax");
}

void X86::writeBitOuExpr() {
  writeTEXT("pop ebx");
  writeTEXT("pop eax");

  writeTEXT("or eax, ebx");

  writeTEXT("push eax");
}

void X86::writeBitXouExpr() {
  writeTEXT("pop ebx");
  writeTEXT("pop eax");

  writeTEXT("xor eax, ebx");

  writeTEXT("push eax");
}

void X86::writeBitEExpr() {
  writeTEXT("pop ebx");
  writeTEXT("pop eax");

  writeTEXT("and eax, ebx");

  writeTEXT("push eax");
}

void X86::writeIgualExpr() {
  writeTEXT("pop ebx");
  writeTEXT("pop eax");

  writeTEXT("cmp eax, ebx");
  writeTEXT("sete al");
  writeTEXT("and eax, 0xff");

  writeTEXT("push eax");
}

void X86::writeDiferenteExpr() {
  writeTEXT("pop ebx");
  writeTEXT("pop eax");

  writeTEXT("cmp eax, ebx");
  writeTEXT("setne al");
  writeTEXT("and eax, 0xff");
  
  writeTEXT("push eax");
}

void X86::writeMaiorExpr(int e1, int e2) {
  writeTEXT("pop ebx");
  writeTEXT("pop eax");

  //fcomp assumes ST0 is left-hand operand aways
  //flags after comp:
  //5.0 @ 4 : ax -> 0
  //5.0 @ 5 : ax -> 0x4000
  //4.0 @ 6 : ax -> 0x100
  if((e1 == TIPO_REAL) || (e2 == TIPO_REAL)) {
    writeTEXT("fninit");
    if((e1 == TIPO_REAL) && (e2 != TIPO_REAL)) { //float/integer
      writeTEXT("mov [__aux], eax");
      writeTEXT("fld dword [__aux]");
      writeTEXT("mov [__aux], ebx");
      writeTEXT("ficomp dword [__aux]");
      writeTEXT("fstsw ax");
      writeTEXT("cmp ax, 0");
    } else if((e1 != TIPO_REAL) && (e2 == TIPO_REAL)) { //integer/float
      writeTEXT("mov [__aux], ebx");
      writeTEXT("fld dword [__aux]");
      writeTEXT("mov [__aux], eax");
      writeTEXT("ficomp dword [__aux]");
      writeTEXT("fstsw ax");
      writeTEXT("cmp ax, 0x100");
    } else { //float/float
      writeTEXT("mov [__aux], eax");
      writeTEXT("fld dword [__aux]");
      writeTEXT("mov [__aux], ebx");
      writeTEXT("fcomp dword [__aux]");
      writeTEXT("fstsw ax");
      writeTEXT("cmp ax, 0");
    }
    writeTEXT("sete al");
    writeTEXT("and eax, 0xff");
  } else {
    writeTEXT("cmp eax, ebx");
    writeTEXT("setg al");
    writeTEXT("and eax, 0xff");
  }
  
  writeTEXT("push eax");
}

void X86::writeMenorExpr(int e1, int e2) {
  writeTEXT("pop ebx");
  writeTEXT("pop eax");

  if((e1 == TIPO_REAL) || (e2 == TIPO_REAL)) {
    writeTEXT("fninit");
    if((e1 == TIPO_REAL) && (e2 != TIPO_REAL)) { //float/integer
      writeTEXT("mov [__aux], eax");
      writeTEXT("fld dword [__aux]");
      writeTEXT("mov [__aux], ebx");
      writeTEXT("ficomp dword [__aux]");
      writeTEXT("fstsw ax");
      writeTEXT("cmp ax, 0x100");
    } else if((e1 != TIPO_REAL) && (e2 == TIPO_REAL)) { //integer/float
      writeTEXT("mov [__aux], ebx");
      writeTEXT("fld dword [__aux]");
      writeTEXT("mov [__aux], eax");
      writeTEXT("ficomp dword [__aux]");
      writeTEXT("fstsw ax");
      writeTEXT("cmp ax, 0");
    } else { //float/float
      writeTEXT("mov [__aux], eax");
      writeTEXT("fld dword [__aux]");
      writeTEXT("mov [__aux], ebx");
      writeTEXT("fcomp dword [__aux]");
      writeTEXT("fstsw ax");
      writeTEXT("cmp ax, 0x100");
    }
    writeTEXT("sete al");
    writeTEXT("and eax, 0xff");
  } else {
    writeTEXT("cmp eax, ebx");
    writeTEXT("setl al");
    writeTEXT("and eax, 0xff");
  }

  writeTEXT("push eax");
}

void X86::writeMaiorEqExpr(int e1, int e2) {
  writeTEXT("pop ebx");
  writeTEXT("pop eax");

  if((e1 == TIPO_REAL) || (e2 == TIPO_REAL)) {
    writeTEXT("fninit");
    if((e1 == TIPO_REAL) && (e2 != TIPO_REAL)) { //float/integer
      writeTEXT("mov [__aux], eax");
      writeTEXT("fld dword [__aux]");
      writeTEXT("mov [__aux], ebx");
      writeTEXT("ficomp dword [__aux]");
      writeTEXT("fstsw ax");
      writeTEXT("cmp ax, 0");
    } else if((e1 != TIPO_REAL) && (e2 == TIPO_REAL)) { //integer/float
      writeTEXT("mov [__aux], ebx");
      writeTEXT("fld dword [__aux]");
      writeTEXT("mov [__aux], eax");
      writeTEXT("ficomp dword [__aux]");
      writeTEXT("fstsw ax");
      writeTEXT("cmp ax, 0x100");
    } else { //float/float
      writeTEXT("mov [__aux], eax");
      writeTEXT("fld dword [__aux]");
      writeTEXT("mov [__aux], ebx");
      writeTEXT("fcomp dword [__aux]");
      writeTEXT("fstsw ax");
      writeTEXT("cmp ax, 0");
    }
    writeTEXT("sete bl");
    writeTEXT("and ebx, 0xff");
    
    writeTEXT("cmp ax, 0x4000");
    writeTEXT("sete al");
    writeTEXT("and eax, 0xff");
    writeTEXT("or eax, ebx");
  } else {
    writeTEXT("cmp eax, ebx");
    writeTEXT("setge al");
    writeTEXT("and eax, 0xff");
  }

  writeTEXT("push eax");
}

void X86::writeMenorEqExpr(int e1, int e2) {
  writeTEXT("pop ebx");
  writeTEXT("pop eax");

  if((e1 == TIPO_REAL) || (e2 == TIPO_REAL)) {
    writeTEXT("fninit");
    if((e1 == TIPO_REAL) && (e2 != TIPO_REAL)) { //float/integer
      writeTEXT("mov [__aux], eax");
      writeTEXT("fld dword [__aux]");
      writeTEXT("mov [__aux], ebx");
      writeTEXT("ficomp dword [__aux]");
      writeTEXT("fstsw ax");
      writeTEXT("cmp ax, 0x100");
    } else if((e1 != TIPO_REAL) && (e2 == TIPO_REAL)) { //integer/float
      writeTEXT("mov [__aux], ebx");
      writeTEXT("fld dword [__aux]");
      writeTEXT("mov [__aux], eax");
      writeTEXT("ficomp dword [__aux]");
      writeTEXT("fstsw ax");
      writeTEXT("cmp ax, 0");
    } else { //float/float
      writeTEXT("mov [__aux], eax");
      writeTEXT("fld dword [__aux]");
      writeTEXT("mov [__aux], ebx");
      writeTEXT("fcomp dword [__aux]");
      writeTEXT("fstsw ax");
      writeTEXT("cmp ax, 0x100");
    }
    writeTEXT("sete bl");
    writeTEXT("and ebx, 0xff");
    
    writeTEXT("cmp ax, 0x4000");
    writeTEXT("sete al");
    writeTEXT("and eax, 0xff");
    writeTEXT("or eax, ebx");
  } else {
    writeTEXT("cmp eax, ebx");
    writeTEXT("setle al");
    writeTEXT("and eax, 0xff");
  }

  writeTEXT("push eax");
}

void X86::writeMaisExpr(int e1, int e2) { 
  writeTEXT("pop ebx");
  writeTEXT("pop eax");

  if((e1 == TIPO_REAL) || (e2 == TIPO_REAL)) {
    string addpop;
    writeTEXT("fninit");
    if((e1 == TIPO_REAL) && (e2 != TIPO_REAL)) { //float/integer
      writeTEXT("mov [__aux], eax");
      writeTEXT("fld dword [__aux]");
      writeTEXT("mov [__aux], ebx");
      addpop = "fiadd dword [__aux]";
    } else if((e1 != TIPO_REAL) && (e2 == TIPO_REAL)) { //integer/float
      writeTEXT("mov [__aux], ebx");
      writeTEXT("fld dword [__aux]");
      writeTEXT("mov [__aux], eax");
      addpop = "fiadd dword [__aux]";
    } else { //float/float
      writeTEXT("mov [__aux], eax");
      writeTEXT("fld dword [__aux]");
      writeTEXT("mov [__aux], ebx");
      addpop = "fadd dword [__aux]";
    }
      writeTEXT(addpop);
      writeTEXT("fstp dword [__aux]");
      writeTEXT("mov eax, dword [__aux]");
  } else {
    writeTEXT("add eax, ebx");    
  }

  writeTEXT("push eax");
}

void X86::writeMenosExpr(int e1, int e2) {
  writeTEXT("pop ebx");
  writeTEXT("pop eax");

  if((e1 == TIPO_REAL) || (e2 == TIPO_REAL)) {
    string subop;
    writeTEXT("fninit");
    if((e1 == TIPO_REAL) && (e2 != TIPO_REAL)) { //float/integer
      writeTEXT("mov [__aux], eax");
      writeTEXT("fld dword [__aux]");
      writeTEXT("mov [__aux], ebx");
      subop = "fisub dword [__aux]";
    } else if((e1 != TIPO_REAL) && (e2 == TIPO_REAL)) { //integer/float
      writeTEXT("mov [__aux], ebx");
      writeTEXT("fld dword [__aux]");
      writeTEXT("mov [__aux], eax");
      subop = "fisub dword [__aux]";
    } else { //float/float
      writeTEXT("mov [__aux], eax");
      writeTEXT("fld dword [__aux]");
      writeTEXT("mov [__aux], ebx");
      subop = "fsub dword [__aux]";
    }
      writeTEXT(subop);
      writeTEXT("fstp dword [__aux]");
      writeTEXT("mov eax, dword [__aux]");
  } else {
    writeTEXT("sub eax, ebx");
  }

  writeTEXT("push eax");
}

void X86::writeDivExpr(int e1, int e2) {
  writeTEXT("pop ebx");
  writeTEXT("pop eax");

  if((e1 == TIPO_REAL) || (e2 == TIPO_REAL)) {
    string divpop;
    writeTEXT("fninit");
    if((e1 == TIPO_REAL) && (e2 != TIPO_REAL)) { //float/integer
      writeTEXT("mov [__aux], eax");
      writeTEXT("fld dword [__aux]");
      writeTEXT("mov [__aux], ebx");
      divpop = "fidiv dword [__aux]";
    } else if((e1 != TIPO_REAL) && (e2 == TIPO_REAL)) { //integer/float
      writeTEXT("mov [__aux], ebx");
      writeTEXT("fld dword [__aux]");
      writeTEXT("mov [__aux], eax");
      divpop = "fidivr dword [__aux]";
    } else { //float/float
      writeTEXT("mov [__aux], eax");
      writeTEXT("fld dword [__aux]");
      writeTEXT("mov [__aux], ebx");
      divpop = "fdiv dword [__aux]";
    }
      writeTEXT(divpop);
      writeTEXT("fstp dword [__aux]");
      writeTEXT("mov eax, dword [__aux]");
  } else {
    writeTEXT("xor edx, edx");
    writeTEXT("idiv ebx");
  }

  writeTEXT("push eax");
}

void X86::writeMultipExpr(int e1, int e2) {
  writeTEXT("pop ebx");
  writeTEXT("pop eax");

  if((e1 == TIPO_REAL) || (e2 == TIPO_REAL)) {
    string mulpop;
    writeTEXT("fninit");
    if((e1 == TIPO_REAL) && (e2 != TIPO_REAL)) { //float/integer
      writeTEXT("mov [__aux], eax");
      writeTEXT("fld dword [__aux]");
      writeTEXT("mov [__aux], ebx");
      mulpop = "fimul dword [__aux]";
    } else if((e1 != TIPO_REAL) && (e2 == TIPO_REAL)) { //integer/float
      writeTEXT("mov [__aux], ebx");
      writeTEXT("fld dword [__aux]");
      writeTEXT("mov [__aux], eax");
      mulpop = "fimul dword [__aux]";
    } else { //float/float
      writeTEXT("mov [__aux], eax");
      writeTEXT("fld dword [__aux]");
      writeTEXT("mov [__aux], ebx");
      mulpop = "fmul dword [__aux]";
    }
      writeTEXT(mulpop);
      writeTEXT("fstp dword [__aux]");
      writeTEXT("mov eax, dword [__aux]");
  } else {
    writeTEXT("imul eax, ebx");
  }

  writeTEXT("push eax");
}

void X86::writeModExpr() {
  writeTEXT("pop ebx");
  writeTEXT("pop eax");

  writeTEXT("xor edx, edx");
  writeTEXT("idiv ebx");        
  writeTEXT("mov eax, edx");

  writeTEXT("push eax");
}

void X86::writeUnaryNeg(int etype) {
  writeTEXT("pop eax");

  stringstream s;
  if(etype == TIPO_REAL) {
    s << "or eax ,0x80000000";
  } else {
    s << "neg eax";          
  }
  writeTEXT(s.str());

  writeTEXT("push eax");
}

void X86::writeUnaryNot() {
  writeTEXT("pop eax");

  writeTEXT("mov ebx, eax");
  writeTEXT("xor eax, eax");
  writeTEXT("cmp ebx, 0");
  writeTEXT("sete al");

  writeTEXT("push eax");
}

void X86::writeUnaryBitNotExpr() {
  writeTEXT("pop eax");
  writeTEXT("not eax");

  writeTEXT("push eax");
}


void X86::writeLiteralExpr(const string& src) {
  stringstream s;
  s << "push " << src;
  writeTEXT(s.str());
}

void X86::writeLValueExpr(pair< pair<int, bool>, string>& lv) {
  stringstream s;
  if(lv.first.second) { //if is primitive
    s << "mov edx, " << lv.second;
  } else {
    s << "mov edx, dword [" << lv.second << "]";
  }
  writeTEXT(s.str());
  s.str("");
  s << "lea edx, [edx+ecx*4]";
  writeTEXT(s.str());
  s.str("");
  s << "push dword [edx]";  
  writeTEXT(s.str());
  //s << "push dword [" << src << " + ecx*4]"; 
  //writeTEXT(s.str());
}



