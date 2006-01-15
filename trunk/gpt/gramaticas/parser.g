/*
 *   Copyright (C) 2005 by Thiago Silva                                    *
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
  #include "BasePortugolParser.hpp"
  #include "PortugolAST.hpp"
  #include "ErrorHandler.hpp"
}

options {
  language="Cpp";  
}

class PortugolParser extends Parser("BasePortugolParser");
options {
  buildAST = true;
  ASTLabelType="RefPortugolAST";
  importVocab=Portugol;  // use vocab generated by lexer
  genHashLines=false;//no #line
}

{  
  public:
    RefPortugolAST getPortugolAST()
    {
      return returnAST;
    }
}
/******************************** GRAMATICA *************************************************/

algoritmo
  : declaracao_algoritmo (var_decl_block)? stm_block (func_decls)* EOF
  ;

  exception //nem "variaveis" nem "inicio"
  catch[antlr::NoViableAltException e] {
    reportParserError(e.getLine(), 
      "\"vari�veis\" ou \"in�cio\" ap�s declara��o de algoritmo", getTokenDescription(e.token));
  }

  catch[antlr::MismatchedTokenException e] { //EOF
    reportParserError(e.getLine(), expecting_eof_or_function, getTokenDescription(e.token));
  }

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
declaracao_algoritmo
  : alg:T_KW_ALGORITMO^ id:T_IDENTIFICADOR T_SEMICOL!
    {_name = id->getText();}
  ;

  exception //T_KW_ALGORITMO, T_IDENTIFICADOR, T_SEMICOL
  catch[antlr::MismatchedTokenException e] {
    if(e.expecting == T_IDENTIFICADOR) {
      if(alg->getLine() != e.getLine()) {
        reportParserError(alg->getLine(), expecting_algorithm_name, "", alg->getText());
      } else {
        reportParserError(e.getLine(), expecting_algorithm_name, getTokenDescription(e.token));
      }
    } else if(e.expecting == T_SEMICOL) {
      reportParserError(id->getLine(), getTokenNames()[e.expecting], "", id->getText());
    } else {
      reportParserError(e.getLine(), getTokenNames()[e.expecting], getTokenDescription(e.token));
    }
    BitSet b;
    b.add(T_KW_VARIAVEIS);
    b.add(T_KW_INICIO);
    consumeUntil(b);
  }

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
var_decl_block  
{RefToken tk;}
  : tvars:T_KW_VARIAVEIS^ (var_decl {tk = lastToken;} semi:T_SEMICOL!)+ T_KW_FIM_VARIAVEIS!
  ;

  //Nota: T_KW_VARIAVEIS ja foi checado.

  exception //nenhum T_IDENTIFICADOR (var_decl)
  catch[antlr::NoViableAltException e] {
    
    int cd;
    if(e.getLine() == tvars->getLine()) {
      cd = reportParserError(e.getLine(), expecting_variable, "", tvars->getText());
    } else {
      cd = reportParserError(e.getLine(), expecting_variable, getTokenDescription(e.token));
    }
    printTip("Pelo menos uma vari�vel deve ser declarada", e.getLine(), cd);
  
    BitSet b;
    b.add(T_KW_INICIO);
    b.add(T_KW_FUNCAO);
    consumeUntil(b); 
  }

  catch[antlr::MismatchedTokenException e] {
    if(e.expecting == T_SEMICOL) {
      if(isDatatype(tk->getType())) {
        reportParserError(tk->getLine(), getTokenNames()[e.expecting], "", tk->getText());
      } /*else {
        reportParserError(tk->getLine(), getTokenNames()[e.expecting], getTokenDescription(e.token));
      }*/
    } else if(e.expecting == T_KW_FIM_VARIAVEIS){
      if(e.getLine() == semi->getLine()) {
        reportParserError(e.getLine(), expecting_fimvar_or_var, "", semi->getText());
      } else {
        reportParserError(e.getLine(), expecting_fimvar_or_var, getTokenDescription(e.token));
      }
    } else {
      reportParserError(e.getLine(), getTokenNames()[e.expecting], getTokenDescription(e.token));
    }
  
    BitSet b;
    b.add(T_KW_VARIAVEIS);
    b.add(T_KW_INICIO);
    consumeUntil(b);
  }

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

var_decl!
{RefToken lastId;}
  : id:T_IDENTIFICADOR {lastToken = id;}
    more:var_more {lastId=lastToken;} colon:T_COLON
     (
         p:tp_prim   {#var_decl = #([TI_VAR_PRIMITIVE,"primitive!"], p, id, more);}
       | m:tp_matriz {#var_decl = #([TI_VAR_MATRIX, "matrix!"], m, id, more);}
     )
  ;

  //Nota: T_IDENTIFICADOR ja foi checado
  exception
  catch[antlr::MismatchedTokenException e] {
  
    if(e.expecting == T_COLON) {
      if((e.token->getType() != EOF_) && (e.getLine() == lastId->getLine())) {
        int cd;
        cd = reportParserError(e.getLine(), getTokenNames()[e.expecting], getTokenDescription(e.token));
  
        if(e.token->getType() == T_IDENTIFICADOR) {
          printTip(string("Coloque uma v�rgula entre as vari�veis \"")
              + lastId->getText() + "\" e \"" + e.token->getText() + "\"", e.getLine(), cd);
        }
        if(isDatatype(e.token->getType())) {
          printTip(string("Coloque ':' entre \"")
            + lastId->getText() + "\" e " + getTokenNames()[LA(1)], e.getLine(), cd);
        }
      } else {
        reportParserError(lastId->getLine(), getTokenNames()[e.expecting], "", lastId->getText());
      }
    }
    lastToken = LT(1);
    consumeUntil(T_SEMICOL);
  }
  
  catch[antlr::NoViableAltException e] { //no datatype
    if(e.getLine() == colon->getLine()) {
      reportParserError(e.getLine(), expecting_datatype,  getTokenDescription(e.token));
    } else {
      reportParserError(e.getLine(), expecting_datatype, "", colon->getText());
    }
    consumeUntil(T_SEMICOL);
  }

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
var_more
{RefToken lst;}
  :  (T_COMMA! {lst=lastToken;} id:T_IDENTIFICADOR {lastToken = id;})*
  ;

  exception
  catch[antlr::MismatchedTokenException e] {
    if(lst->getLine() == e.getLine()) {
      reportParserError(e.getLine(), expecting_variable, getTokenDescription(e.token));
    } else {
      reportParserError(e.getLine(), expecting_variable, "", lst->getText());
    }
    consumeUntil(T_COLON);
  }
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
tp_prim
{RefToken tk=lastToken;}
  : T_KW_INTEIRO
  | T_KW_REAL
  | T_KW_CARACTERE
  | T_KW_LITERAL
  | T_KW_LOGICO
  ;


  exception //for function return
  catch[antlr::NoViableAltException e] {
    if(e.getLine() == tk->getLine()) {
      reportParserError(e.getLine(), expecting_datatype, getTokenDescription(e.token));
    } else {
      reportParserError(tk->getLine(), expecting_datatype, "", tk->getText());
    }
    BitSet b;
    b.add(T_SEMICOL);//next for decl var
    b.add(T_KW_INICIO); //next for rettype
    consumeUntil(b);
  }

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

tp_matriz!
{RefToken lst;}
  : mt:T_KW_MATRIZ dim:dimensoes {lst=lastToken;}T_KW_DE tipo:tp_prim_pl
    {#tp_matriz = #(tipo, dim);}    
  ;

  exception
  catch[antlr::MismatchedTokenException e] {
    if(lst->getType() == T_FECHAC) {
      if(e.getLine() == mt->getLine()) {    
        reportParserError(e.getLine(), getTokenNames()[e.expecting], getTokenDescription(e.token));
      } else {
        reportParserError(mt->getLine(), getTokenNames()[e.expecting], "", lst->getText());
      }
    }//else: dimensoes deu erro. Nao reporte nada aqui.
    
    consumeUntil(T_SEMICOL);
  }

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

dimensoes
{
  RefToken mt = lastToken;
  RefToken lst;
}
  : (
      abre:T_ABREC!
        {lst=abre;}
      size:T_INT_LIT 
        {lst=size;}
      fecha:T_FECHAC!
        {lst=fecha;}
    )+
  ;

  exception
  catch[antlr::MismatchedTokenException e] {
    
    if(e.getLine() == lst->getLine()) {
      reportParserError(e.getLine(), getTokenNames()[e.expecting], "", lst->getText());//getTokenDescription(e.token));
    } else {
      reportParserError(lst->getLine(), getTokenNames()[e.expecting], "", lst->getText());
    }
    consumeUntil(T_KW_DE);
  }

  catch[antlr::NoViableAltException e] {
    if(mt->getLine() == e.getLine()) {
      reportParserError(e.getLine(), getTokenNames()[T_ABREC], "", mt->getText());
    } else {
      reportParserError(mt->getLine(), getTokenNames()[T_ABREC], "", mt->getText());
    }
    consumeUntil(T_KW_DE);
  }

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

tp_prim_pl
{RefToken lst=lastToken;}
  : T_KW_INTEIROS
  | T_KW_REAIS
  | T_KW_CARACTERES
  | T_KW_LITERAIS
  | T_KW_LOGICOS
  ;

exception
catch[antlr::NoViableAltException e] {
  if(lst->getLine() == e.getLine()) {
    reportParserError(e.getLine(), expecting_datatype, getTokenDescription(e.token));
  } else {
    reportParserError(lst->getLine(), expecting_datatype, "", lst->getText());
  }
  consumeUntil(T_SEMICOL);
}
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

stm_block!
{RefToken lst = lastToken;}
  : T_KW_INICIO stms:stm_list T_KW_FIM
      {#stm_block = #(T_KW_INICIO, stms);}
  ;

  exception
  catch[antlr::MismatchedTokenException e] {
    if(e.expecting == T_KW_FIM) {
      int cd = reportParserError(e.getLine(), expecting_stm_or_fim, getTokenDescription(e.token));
      if(e.token->getType() == T_IDENTIFICADOR) {
        printTip(string("Verifique o uso de \"[]\" (caso \"") + e.token->getText() + 
                       "\" seja um vetor/matriz), do operador \":=\" (caso seja um comando de atribui��o)"
                       " e do uso de par�ntesis (caso \"" + e.token->getText() +
                       "\" seja uma chamada de fun��o)", e.getLine(), cd);

/*        printTip(string("se \"") + e.token->getText() 
          + "\" � uma vari�vel, verifique o uso de \"[]\" caso seja um vetor/matriz adicione o operador de atribui��o " + getTokenNames()[T_ATTR]
          + " logo ap�s. Se for uma fun��o, adicione " +  getTokenNames()[T_ABREP] , e.getLine(), cd);*/
      } 
    } else {
      reportParserError(e.getLine(), getTokenNames()[e.expecting], getTokenDescription(e.token));
    }
  
    BitSet b;
    b.add(EOF_);
    b.add(T_KW_FUNCAO);
    consumeUntil(b);
  }

//   catch[antlr::NoViableAltException e] {
//     cerr << "stm_block:NoViableAltException\n";
//   }

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

stm_list
{RefToken tk=lastToken;}
  : ( (lvalue T_ATTR)=> stm_attr {tk=lastToken;} T_SEMICOL!
      | {(LA(1) == T_IDENTIFICADOR) && (LA(2)==T_ABREP)}? fcall {tk=lastToken;} T_SEMICOL!
      | stm_ret {tk=lastToken;} T_SEMICOL!
      | stm_se
      | stm_enquanto
      | stm_para
    )*
  ;

  //Nota: caso haja excecao em (stm_list)*, n�o haver� outra tentativa (causada pelo *),
  //      isso eh, a funcao stm_list retornara.
  exception
  catch[antlr::MismatchedTokenException e] {
    if(e.expecting == T_SEMICOL) {
      if(tk->getLine() == e.getLine()) {
        reportParserError(tk->getLine(), getTokenNames()[e.expecting], getTokenDescription(e.token));
      } else {
        reportParserError(tk->getLine(), getTokenNames()[e.expecting], "", tk->getText());
      }
    }
  
    BitSet b;
    b.add(T_KW_FIM_SE);
    b.add(T_KW_FIM_ENQUANTO);
    b.add(T_KW_FIM_PARA);
    b.add(T_KW_FIM);
    consumeUntil(b);
  }

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

stm_ret!
  : t:T_KW_RETORNE^ (e:expr {#stm_ret = #(t,e);}|{#stm_ret = #(t,[TI_NULL,"null!"]);})
  ;

  exception
  catch[antlr::NoViableAltException e] {
    reportParserError(lastToken->getLine(), expecting_expression, "", lastToken->getText());
  
    //tudo o que vem depois de stm_list
    BitSet b;
    b.add(T_IDENTIFICADOR);
    b.add(T_KW_RETORNE);
    b.add(T_KW_SE);
    b.add(T_KW_ENQUANTO);
    b.add(T_KW_PARA);
    b.add(T_KW_SENAO);
    b.add(T_KW_FIM_SE);
    b.add(T_KW_FIM_ENQUANTO);
    b.add(T_KW_FIM_PARA);
    b.add(T_KW_FIM);
    consumeUntil(b);
  }

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

array_sub
{RefToken tk;}
  : (T_ABREC! expr {tk = lastToken;}T_FECHAC!)*
  ;

  exception //apenas para rvalue. se array_sub pertence a um lvalue, ele ja foi validado porcausa
            //do predicado em stm_list
  catch[antlr::MismatchedTokenException e] {
    reportParserError(tk->getLine(), getTokenNames()[e.expecting], "", tk->getText());
  
    //consumeUntil: para tudo o que vem depois de lvalue
    BitSet b;
    b.add(T_ATTR);
    b.add(T_KW_DE);
    //+ tudo o que vem depois de expr
    b.add(T_SEMICOL);
    b.add(T_FECHAC);
    b.add(T_KW_ENTAO);
    b.add(T_KW_FACA);
    b.add(T_KW_ATE);
    consumeUntil(b);
  }

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
lvalue!
{RefToken lst=lastToken;}
  : id:T_IDENTIFICADOR
    s:array_sub
    {#lvalue = #(id, s);}
  ;

  exception
  catch[antlr::MismatchedTokenException e] {
    if(lst->getLine() == e.getLine()) {
      reportParserError(e.getLine(), expecting_variable, getTokenDescription(e.token));
    } else {
      reportParserError(lst->getLine(), expecting_variable, "", lst->getText());
    }  
    //tudo o que vem depois de lvalue
    BitSet b;
    b.add(T_ATTR);
    b.add(T_KW_DE);  
    //+tudo o que vem depois de expr
    b.add(T_SEMICOL);
    b.add(T_FECHAC);
    b.add(T_KW_ENTAO);
    b.add(T_KW_FACA);
    b.add(T_KW_ATE);
    consumeUntil(b);
  }

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

stm_attr
  : lvalue T_ATTR^ expr
  ;

//nao precisa de catch[]. tokens ja foram validados no predicado em stm_list

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
stm_se
{RefToken tk;}
  : T_KW_SE^ expr {tk=lastToken;} T_KW_ENTAO! {tk=lastToken;} stm_list (T_KW_SENAO stm_list)? {tk=lastToken;} T_KW_FIM_SE!
  ;

  exception
  catch[antlr::MismatchedTokenException e] {
    if(e.expecting != T_KW_FIM_SE) {
      if(e.getLine() == tk->getLine()) {
        reportParserError(e.getLine(), getTokenNames()[e.expecting], getTokenDescription(e.token));
      } else {
        reportParserError(tk->getLine(), getTokenNames()[e.expecting], "", tk->getText());
      }
    } else {
      if(e.getLine() == tk->getLine()) {
        reportParserError(e.getLine(), expecting_stm_or_fimse, getTokenDescription(e.token));
      } else {
        reportParserError(tk->getLine(), expecting_stm_or_fimse, "", tk->getText());
      }  
    }
    //tudo o que vem depois de stm_list
    BitSet b;
    b.add(T_IDENTIFICADOR);
    b.add(T_KW_RETORNE);
    b.add(T_KW_SE);
    b.add(T_KW_ENQUANTO);
    b.add(T_KW_PARA);
    b.add(T_KW_SENAO);
    b.add(T_KW_FIM_SE);
    b.add(T_KW_FIM_ENQUANTO);
    b.add(T_KW_FIM_PARA);
    b.add(T_KW_FIM);
    consumeUntil(b);
  }

  catch[antlr::NoViableAltException e] { //fimse
    if(e.getLine() == tk->getLine()) {
      reportParserError(e.getLine(), expecting_stm_or_fimse, getTokenDescription(e.token));
    } else {
      reportParserError(tk->getLine(), expecting_stm_or_fimse, "", tk->getText());
    }  
    //tudo o que vem depois de stm_list
    BitSet b;
    b.add(T_IDENTIFICADOR);
    b.add(T_KW_RETORNE);
    b.add(T_KW_SE);
    b.add(T_KW_ENQUANTO);
    b.add(T_KW_PARA);
    b.add(T_KW_SENAO);
    b.add(T_KW_FIM_SE);
    b.add(T_KW_FIM_ENQUANTO);
    b.add(T_KW_FIM_PARA);
    b.add(T_KW_FIM);
    consumeUntil(b);
  }

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

stm_enquanto
{RefToken tk;}
  : T_KW_ENQUANTO^ expr {tk=lastToken;} T_KW_FACA! {tk=lastToken;} stm_list {tk=lastToken;} T_KW_FIM_ENQUANTO!
  ;

  exception
  catch[antlr::MismatchedTokenException e] {
    if(e.expecting != T_KW_FIM_ENQUANTO) {
      if(e.getLine() == tk->getLine()) {
        reportParserError(e.getLine(), getTokenNames()[e.expecting], getTokenDescription(e.token));
      } else {
        reportParserError(tk->getLine(), getTokenNames()[e.expecting], "", tk->getText());
      }
    } else {
      if(e.getLine() == tk->getLine()) {
        reportParserError(e.getLine(), expecting_stm_or_fimenq, getTokenDescription(e.token));
      } else {
        reportParserError(tk->getLine(), expecting_stm_or_fimenq, "", tk->getText());
      }  
    }
    //tudo o que vem depois de stm_list
    BitSet b;
    b.add(T_IDENTIFICADOR);
    b.add(T_KW_RETORNE);
    b.add(T_KW_SE);
    b.add(T_KW_ENQUANTO);
    b.add(T_KW_PARA);
    b.add(T_KW_SENAO);
    b.add(T_KW_FIM_SE);
    b.add(T_KW_FIM_ENQUANTO);
    b.add(T_KW_FIM_PARA);
    b.add(T_KW_FIM);
    consumeUntil(b);
  }

  //nota: stm_enquanto nao lanca noViable

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
stm_para 
{RefToken tk;}
  : T_KW_PARA^ 
    lvalue {tk=lastToken;} 
    T_KW_DE! {tk=lastToken;} 
    expr {tk=lastToken;}
    T_KW_ATE!
    expr {tk=lastToken;} 
    passo {tk=lastToken;} 
    T_KW_FACA! {tk=lastToken;} 
    stm_list {tk=lastToken;}
    T_KW_FIM_PARA!
  ;

  exception
  catch[antlr::MismatchedTokenException e] {
    if(e.expecting != T_KW_FIM_PARA) {
      if(e.getLine() == tk->getLine()) {
        reportParserError(e.getLine(), getTokenNames()[e.expecting], getTokenDescription(e.token));
      } else {
        reportParserError(tk->getLine(), getTokenNames()[e.expecting], "", tk->getText());
      }
    } else {
      if(e.getLine() == tk->getLine()) {
        reportParserError(e.getLine(), expecting_stm_or_fimpara, getTokenDescription(e.token));
      } else {
        reportParserError(tk->getLine(), expecting_stm_or_fimpara, "", tk->getText());
      }  
    }
    //tudo o que vem depois de stm_list
    BitSet b;
    b.add(T_IDENTIFICADOR);
    b.add(T_KW_RETORNE);
    b.add(T_KW_SE);
    b.add(T_KW_ENQUANTO);
    b.add(T_KW_PARA);
    b.add(T_KW_SENAO);
    b.add(T_KW_FIM_SE);
    b.add(T_KW_FIM_ENQUANTO);
    b.add(T_KW_FIM_PARA);
    b.add(T_KW_FIM);
    consumeUntil(b);
  }

passo
{RefToken tk=LT(1);}
  : (T_KW_PASSO^ {tk=lastToken;} (T_MAIS|T_MENOS)? {tk=lastToken;} T_INT_LIT)?
  ;

  exception
  catch[antlr::NoViableAltException e] {
    // passo faz lookahead para checar T_KW_FACA
    if(tk->getType() != T_KW_PASSO) {
      if(e.getLine() == tk->getLine()) {
        reportParserError(e.getLine(), getTokenNames()[T_KW_FACA], getTokenDescription(e.token));
      } else {
        reportParserError(tk->getLine(), getTokenNames()[T_KW_FACA], "", tk->getText());
      }
    } else {
      reportParserError(tk->getLine(), getTokenNames()[T_INT_LIT], "", tk->getText());
      consumeUntil(T_KW_FACA);
    }  
  }
  
  catch[antlr::MismatchedTokenException e] {
    if(e.getLine() == tk->getLine()) {
      reportParserError(e.getLine(), getTokenNames()[e.expecting], getTokenDescription(e.token));
    } else {
      reportParserError(e.getLine(), getTokenNames()[e.expecting], "", tk->getText());
    }
    consumeUntil(T_KW_FACA);
  }




/* ----------------------------- Expressoes ---------------------------------- */




expr
  : expr_e (T_KW_OU^ expr)?
  ;

  exception //catch todas as excecoes nas expr_*
  catch[ANTLR_USE_NAMESPACE(antlr)NoViableAltException e] {
    //nothing
  }
  
expr_e 
options {
  defaultErrorHandler=false; //noviable should be caught on expr
}
  : expr_bit_ou (T_KW_E^ expr_e)?
  ;

expr_bit_ou
options {
  defaultErrorHandler=false; //noviable should be caught on expr
}
  : expr_bit_xou (T_BIT_OU^ expr_bit_ou)?
  ;

expr_bit_xou 
options {
  defaultErrorHandler=false; //noviable should be caught on expr
}
  : expr_bit_e (T_BIT_XOU^ expr_bit_xou)?
  ;

expr_bit_e
options {
  defaultErrorHandler=false; //noviable should be caught on expr
}
  : expr_igual (T_BIT_E^ expr_bit_e)?
  ;
  
expr_igual
options {
  defaultErrorHandler=false; //noviable should be caught on expr
}
  : expr_relacional (T_IGUAL^ expr_igual|T_DIFERENTE^ expr_igual)?
  ;
        
expr_relacional
options {
  defaultErrorHandler=false; //noviable should be caught on expr
}
  : expr_ad ((T_MAIOR^| T_MAIOR_EQ^| T_MENOR^| T_MENOR_EQ^) expr_relacional)?
  ;

expr_ad
options {
  defaultErrorHandler=false; //noviable should be caught on expr
}
  : expr_multip (T_MAIS^ expr_ad| T_MENOS^ expr_ad)?
  ;

expr_multip 
options {
  defaultErrorHandler=false; //noviable should be caught on expr
}
  : expr_unario (( T_DIV^ | T_MULTIP^ | T_MOD^ ) expr_multip)?
  ;

expr_unario!
options {
  defaultErrorHandler=false; //noviable should be caught on expr
}
  : o:op_unario e:expr_elemento {#expr_unario = #(o, e);}
  ;

op_unario!
  : (
        T_MENOS   {#op_unario = #[TI_UN_NEG,"-"];}
      | T_MAIS    {#op_unario = #[TI_UN_POS,"+"];}
      | T_KW_NOT  {#op_unario = #[TI_UN_NOT,"n�o"];}
      | T_BIT_NOT {#op_unario = #[TI_UN_BNOT,"~"];}
    )?
  ; 

  exception  //op_unario faz um lookahead e lanca noViable 
            //se LA(1) nao servir em nenhuma alternativa de expr_elemento
  catch[ANTLR_USE_NAMESPACE(antlr)NoViableAltException e] {
  
    if(lastToken->getLine() == e.getLine()) {
      reportParserError(e.getLine(), expecting_expression, getTokenDescription(e.token), lastToken->getText());  
    } else {
      reportParserError(lastToken->getLine(), expecting_expression, "", lastToken->getText());
    }
  
    //proximos tokens possiveis (nao-opicionais) apos expr
    BitSet b;
    b.add(T_SEMICOL);
    b.add(T_FECHAC);
    b.add(T_KW_ENTAO);
    b.add(T_KW_FACA);
    b.add(T_KW_ATE);
    consumeUntil(b);
  }

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

expr_elemento
  : (T_IDENTIFICADOR T_ABREP)=> fcall  
  | lvalue
  | literal
  |! T_ABREP e:expr T_FECHAP {#expr_elemento = #([TI_PARENTHESIS,"!par"], e);}
  ;

  exception //ja foi tratado em op_unario
  catch[ANTLR_USE_NAMESPACE(antlr)NoViableAltException e] {
    //nothing
  }

/*************************************************************************************/

fcall!
{RefToken tk;}
  : id:T_IDENTIFICADOR T_ABREP a:fargs {tk=lastToken;} T_FECHAP {#fcall = #([TI_FCALL,"fcall!"], id, a);}
  ; 

  exception //T_FECHAP
  catch[antlr::MismatchedTokenException e] {
  
    if(tk->getLine() == e.getLine()) {
      int cd = reportParserError(e.getLine(), getTokenNames()[e.expecting], getTokenDescription(e.token));
      if((e.token->getType() == T_IDENTIFICADOR)
        || (e.token->getType() == T_STRING_LIT)
        || (e.token->getType() == T_INT_LIT)
        || (e.token->getType() == T_REAL_LIT)
        || (e.token->getType() == T_CARAC_LIT)) {
        printTip(string("Coloque uma v�rgula antes de \"") + e.token->getText() + "\"",e.getLine(),cd);
      }
    } else {
      reportParserError(tk->getLine(), getTokenNames()[e.expecting], "", tk->getText());  
    }
  
    //tudo o que vem depois de expr
    BitSet b;
    b.add(T_SEMICOL);
    b.add(T_FECHAC);
    b.add(T_KW_ENTAO);
    b.add(T_KW_FACA);
    b.add(T_KW_ATE);
    consumeUntil(b);
  }

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

fargs
{RefToken lst=lastToken;}
  : (expr (T_COMMA! expr)*)?
  ;

  exception
  catch[ANTLR_USE_NAMESPACE(antlr)NoViableAltException e] {
  
    if(lst->getLine() == e.getLine()) {
      reportParserError(e.getLine(), expecting_expression, getTokenDescription(e.token));  
    } else {
      reportParserError(lst->getLine(), expecting_expression, "", lst->getText());
    }
    consumeUntil(T_FECHAP);
  }

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

literal
  : T_STRING_LIT
  | T_INT_LIT
  | T_REAL_LIT
  | T_CARAC_LIT
  | T_KW_VERDADEIRO 
  | T_KW_FALSO
  ;

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

func_decls!
{RefToken tk;}
  : f:T_KW_FUNCAO id:T_IDENTIFICADOR T_ABREP params:fparams {tk=lastToken;}T_FECHAP ret:rettype 
    fvars:fvar_decl
    block:stm_block

    {#func_decls = #(id, params, ret, fvars, block);}
  ;

  exception
  catch[antlr::MismatchedTokenException e] {

    if(e.expecting == T_IDENTIFICADOR) {
      if(f->getLine() == e.getLine()) {
        reportParserError(e.getLine(), expecting_function_name, getTokenDescription(e.token));
      } else {
        reportParserError(f->getLine(), expecting_function_name, "", f->getText());
      }
      consumeUntil(T_ABREP);
    } else if(e.expecting == T_ABREP) { 
      if(id->getLine() == e.getLine()) {
        reportParserError(e.getLine(), getTokenNames()[e.expecting], getTokenDescription(e.token));
      } else {
        reportParserError(f->getLine(), getTokenNames()[e.expecting], "", id->getText());
      }
      consumeUntil(T_FECHAP);
    } else if(e.expecting == T_FECHAP) {
      if(tk->getLine() == e.getLine()) {
        reportParserError(e.getLine(), getTokenNames()[e.expecting], getTokenDescription(e.token));
      } else {
        reportParserError(tk->getLine(), getTokenNames()[e.expecting], "", tk->getText());
      }
      consumeUntil(T_KW_INICIO);
    } else {
        cerr << "no message for this error! (func_decls::MismatchedTokenException)\n";
//       cerr << "func_decls:for what is this?" << endl;
//       reportParserError(e.getLine(), getTokenNames()[e.expecting], getTokenDescription(e.token));
    }
  }

//   catch[ANTLR_USE_NAMESPACE(antlr)NoViableAltException e] {
//     cerr << "func_decls::NoViableAltException" << endl;
//     reportParserError(e.getLine(), getTokenNames()[T_KW_INICIO], getTokenDescription(e.token));
//     consumeUntil(T_KW_FIM);
//   }

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

rettype
  : (T_COLON! p:tp_prim   {#rettype = #([TI_FRETURN,"rettype!"], p);} )?
  ;

  exception //rettype does lookahead
  catch[antlr::NoViableAltException e] {
//     cerr << "rettype:NoViableAltException\n";
//     reportParserError(e.getLine(), getTokenNames()[T_KW_INICIO], getTokenDescription(e.token));
//     consumeUntil(T_KW_FIM);    
  }

  catch[antlr::MismatchedTokenException e] {
//     cerr << "rettype:MismatchedTokenException\n";
  }
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

fffvar_decl
{RefToken tk;}
  : (var_decl {tk=lastToken;} T_SEMICOL!)+
  ;

  exception //T_SEMICOL
  catch[antlr::MismatchedTokenException e] {
    if(tk->getLine() == e.getLine()) {
      reportParserError(e.getLine(), getTokenNames()[e.expecting], getTokenDescription(e.token));
    } else {
      reportParserError(tk->getLine(), getTokenNames()[e.expecting], "", tk->getText());
    }
    consumeUntil(T_KW_INICIO);
  }

  catch[ANTLR_USE_NAMESPACE(antlr)NoViableAltException e] {
//     cerr << "fffvar_decl::NoViableAltException" << endl;
  }
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

fvar_decl!
  : ( s:fffvar_decl {#fvar_decl = #([T_KW_VARIAVEIS,"vari�veis!"],s);} )?
  ;

  exception
  catch[antlr::NoViableAltException e] {
//     cerr << "fvar_decl::NoViableAltException" << endl;
  }

//   catch[antlr::MismatchedTokenException e] {
//     cerr << "fvar_decl::MismatchedTokenException" << endl;
//   }


//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

fparams
{RefToken tk = lastToken;}
  : (fparam (T_COMMA! fparam)*)?
  ;

  exception
  catch[ANTLR_USE_NAMESPACE(antlr)NoViableAltException e] {
    if(e.getLine() == tk->getLine()) {
      reportParserError(e.getLine(), expecting_param_or_fparen, getTokenDescription(e.token));
    } else {
      reportParserError(tk->getLine(), expecting_param_or_fparen, "", tk->getText());
    }
    consumeUntil(T_FECHAP);
  }


//   catch[antlr::MismatchedTokenException e] {
//     cerr << "fparams::MismatchedTokenException" << endl;
//   }

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

fparam!
{RefToken tk=lastToken;}
  : id:T_IDENTIFICADOR col:T_COLON {tk=lastToken;}
     (
         p:tp_prim   {#fparam = #([TI_VAR_PRIMITIVE,"primitive!"], p, id);}
       | m:tp_matriz {#fparam = #([TI_VAR_MATRIX, "matrix!"], m, id);}
     )
  ;

  exception
  catch[antlr::MismatchedTokenException e] {
    if(e.expecting == T_IDENTIFICADOR) {
      if(e.getLine() == tk->getLine()) {
        reportParserError(e.getLine(), expecting_variable, getTokenDescription(e.token));
      } else {
        reportParserError(tk->getLine(), expecting_variable, "", tk->getText());
      }
    } else { //missing colon
      reportParserError(e.getLine(), getTokenNames()[e.expecting], "", id->getText());
    }
    consumeUntil(T_FECHAP);
  }


  catch[ANTLR_USE_NAMESPACE(antlr)NoViableAltException e] {
    //no datatype found
    if(tk->getLine() == e.getLine()) {
      reportParserError(e.getLine(), expecting_datatype, getTokenDescription(e.token));
    } else {
      reportParserError(tk->getLine(), expecting_datatype, "", tk->getText());
    }
    consumeUntil(T_FECHAP);
  }
