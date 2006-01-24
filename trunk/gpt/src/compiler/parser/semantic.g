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
  #include "SemanticEval.hpp"
  #include "SymbolTable.hpp"

  #include <list>
  
  using namespace std;
}

options {
  language="Cpp";  
}

class SemanticWalker extends TreeParser;
options {
  importVocab=Portugol;  // use vocab generated by lexer
  ASTLabelType="RefPortugolAST";
  noConstructors=true;
  genHashLines=false;//no #line
}

{
  public:
    SemanticWalker(SymbolTable& st)
      : evaluator(st) {
    }

  private:
    SemanticEval evaluator;
}

/****************************** TREE WALKER *********************************************/

algoritmo
{RefPortugolAST inicio_;}
  : {
      _t = _t->getNextSibling(); //pula declaracao de algoritmo
      evaluator.setCurrentScope(SymbolTable::GlobalScope);
    } 
    (variaveis)?

    {
      //pula para a declara��o de fun��es
      inicio_ = _t;
      _t = _t->getNextSibling();
    }

    //registra todas as declaracoes de funcoes
    (func_proto)*

    {
      //volta para o bloco principal
      _t = inicio_;
      evaluator.setCurrentScope(SymbolTable::GlobalScope);      
    }

    //analisa o bloco principal
    inicio

    //analisa as funcoes
    (func_decl)*
  { 
    evaluator.setCurrentScope(SymbolTable::GlobalScope);
//     evaluator.evaluateAllFCalls();
  }
  ;

variaveis
{
  pair<int, list<RefPortugolAST> > prims;
  pair< pair<int, list<int> >, list<RefPortugolAST> > ms;
}
  : #(T_KW_VARIAVEIS
      (
          prims=primitivo {evaluator.declareVars(prims);}
        | ms=matriz    {evaluator.declareVars(ms);}
      )+ 
    )
  ;

primitivo returns [pair<int, list<RefPortugolAST> >  p]
{int type;}
  : #(TI_VAR_PRIMITIVE type=tipo_prim {p.first = type;}
      (
        id:T_IDENTIFICADOR  {p.second.push_back(id);}
      )+ 
    )
  ;

tipo_prim returns [int type]
  : T_KW_INTEIRO   {type = TIPO_INTEIRO;}
  | T_KW_REAL      {type = TIPO_REAL;}
  | T_KW_CARACTERE {type = TIPO_CARACTERE;}
  | T_KW_LITERAL   {type = TIPO_LITERAL;}
  | T_KW_LOGICO    {type = TIPO_LOGICO;}
  ;

//pair< pair<type,list<dimensions> >, list<ids> >
matriz returns [pair< pair<int, list<int> >, list<RefPortugolAST> > m]
{pair<int, list<int> > tipo;}
  : #(TI_VAR_MATRIX tipo=tipo_matriz {m.first=tipo;} (id:T_IDENTIFICADOR {m.second.push_back(id);})+)
  ;

tipo_matriz  returns [pair<int, list<int> > p]//pair<type, list<dimensions> >
  : #(T_KW_INTEIROS 
      {p.first = TIPO_INTEIRO;}
      (
        s1:T_INT_LIT
        {p.second.push_back(atoi(s1->getText().c_str()));}
      )+
    )
  | #(T_KW_REAIS
      {p.first = TIPO_REAL;}
      (
        s2:T_INT_LIT
        {p.second.push_back(atoi(s2->getText().c_str()));}
      )+
    )
  | #(T_KW_CARACTERES
      {p.first = TIPO_CARACTERE;}
      (
        s3:T_INT_LIT
        {p.second.push_back(atoi(s3->getText().c_str()));}
      )+
    )
  | #(T_KW_LITERAIS
      {p.first = TIPO_LITERAL;}
      (
        s4:T_INT_LIT
        {p.second.push_back(atoi(s4->getText().c_str()));}
      )+
    )
  | #(T_KW_LOGICOS
      {p.first = TIPO_LOGICO;}
      (
        s5:T_INT_LIT
        {p.second.push_back(atoi(s5->getText().c_str()));}
      )+
    )
  ;


inicio
  : #(T_KW_INICIO (stm)* )
  ;

stm
{ExpressionValue devnull;}
  : stm_attr
  | devnull=fcall //reprimir o warning
  | stm_ret
  | stm_se
  | stm_enquanto
  | stm_para
  ;

stm_attr
{ExpressionValue ltype, etype;}
  : #(t:T_ATTR ltype=lvalue etype=expr)
    {evaluator.evaluateAttribution(ltype, etype, t->getLine());}
  ;

lvalue returns [ExpressionValue type]
{
  ExpressionValue etype;
  list<ExpressionValue> dimensions;
}
  : #(id:T_IDENTIFICADOR
      (
        etype=expr {dimensions.push_back(etype);}
      )*
    )
    {
      type = evaluator.evaluateLValue(id, dimensions);//checa se id eh uma matriz de N dimensoes
    }
  ;

fcall returns [ExpressionValue rettype]
{
  ExpressionValue etype;
  list<ExpressionValue> args;//arg types
}
  : #(TI_FCALL id:T_IDENTIFICADOR 
      (
        etype=expr
        {args.push_back(etype);}
      )*
    )
    {
      rettype = evaluator.evaluateFCall(id, args); //check if f() exists, check for arguments.      
    }
  ;
stm_ret
{ExpressionValue etype;}
  : #(r:T_KW_RETORNE (TI_NULL|etype=expr))
    {evaluator.evaluateReturnCmd(etype, r->getLine());}
  ;

stm_se
{ExpressionValue etype;}
  : #(s:T_KW_SE etype=expr {evaluator.evaluateBooleanExpr(etype, s->getLine());} (stm)*   (T_KW_SENAO (stm)*)? )
  ;

stm_enquanto
{ExpressionValue etype;}
  : #(e:T_KW_ENQUANTO etype=expr {evaluator.evaluateBooleanExpr(etype, e->getLine());} (stm)* )
  ;

stm_para
{ExpressionValue lv, de, ate;}
  : #(p:T_KW_PARA 
        lv=lvalue {evaluator.evaluateNumericExpr(lv, p->getLine());} 
        de=expr   {evaluator.evaluateNumericExpr(de, p->getLine());} 
        ate=expr  {evaluator.evaluateNumericExpr(ate, p->getLine());} 
        (passo)? (stm)* 
    )
  ;

passo
  : #(T_KW_PASSO (T_MAIS|T_MENOS)? i:T_INT_LIT) {evaluator.evaluatePasso(i->getLine(),i->getText());}
  ;

expr returns [ExpressionValue type]
{ExpressionValue left, right;}
  : #(ou:T_KW_OU       left=expr right=expr) {type=evaluator.evaluateExpr(left, right, ou);#expr->setEvalType(type.primitiveType());}
  | #(e:T_KW_E         left=expr right=expr) {type=evaluator.evaluateExpr(left, right, e);#expr->setEvalType(type.primitiveType());}
  | #(bou:T_BIT_OU     left=expr right=expr) {type=evaluator.evaluateExpr(left, right, bou);#expr->setEvalType(type.primitiveType());}
  | #(bxou:T_BIT_XOU   left=expr right=expr) {type=evaluator.evaluateExpr(left, right, bxou);#expr->setEvalType(type.primitiveType());}
  | #(be:T_BIT_E       left=expr right=expr) {type=evaluator.evaluateExpr(left, right, be);#expr->setEvalType(type.primitiveType());}
  | #(ig:T_IGUAL       left=expr right=expr) {type=evaluator.evaluateExpr(left, right, ig);#expr->setEvalType(type.primitiveType());}
  | #(df:T_DIFERENTE   left=expr right=expr) {type=evaluator.evaluateExpr(left, right, df);#expr->setEvalType(type.primitiveType());}
  | #(ma:T_MAIOR       left=expr right=expr) {type=evaluator.evaluateExpr(left, right, ma);#expr->setEvalType(type.primitiveType());}
  | #(me:T_MENOR       left=expr right=expr) {type=evaluator.evaluateExpr(left, right, me);#expr->setEvalType(type.primitiveType());}
  | #(mai:T_MAIOR_EQ   left=expr right=expr) {type=evaluator.evaluateExpr(left, right, mai);#expr->setEvalType(type.primitiveType());}
  | #(mei:T_MENOR_EQ   left=expr right=expr) {type=evaluator.evaluateExpr(left, right, mei);#expr->setEvalType(type.primitiveType());}
  | #(p:T_MAIS         left=expr right=expr) {type=evaluator.evaluateExpr(left, right, p);#expr->setEvalType(type.primitiveType());}
  | #(mi:T_MENOS       left=expr right=expr) {type=evaluator.evaluateExpr(left, right, mi);#expr->setEvalType(type.primitiveType());}
  | #(d:T_DIV          left=expr right=expr) {type=evaluator.evaluateExpr(left, right, d);#expr->setEvalType(type.primitiveType());}
  | #(mu:T_MULTIP      left=expr right=expr) {type=evaluator.evaluateExpr(left, right, mu);#expr->setEvalType(type.primitiveType());}
  | #(mo:T_MOD         left=expr right=expr) {type=evaluator.evaluateExpr(left, right, mo);#expr->setEvalType(type.primitiveType());}
  | #(un:TI_UN_NEG        right=element) {type=evaluator.evaluateExpr(right, un);#expr->setEvalType(type.primitiveType());}
  | #(up:TI_UN_POS        right=element) {type=evaluator.evaluateExpr(right, up);#expr->setEvalType(type.primitiveType());}
  | #(unn:TI_UN_NOT       right=element) {type=evaluator.evaluateExpr(right, unn);#expr->setEvalType(type.primitiveType());}
  | #(unb:TI_UN_BNOT      right=element) {type=evaluator.evaluateExpr(right, unb);#expr->setEvalType(type.primitiveType());}
  | type=element {#expr->setEvalType(type.primitiveType());}
  ;


element returns [ExpressionValue type]
  : type=literal
  | type=fcall
  | type=lvalue
  | #(TI_PARENTHESIS type=expr)
  ;

literal returns [ExpressionValue type]
  : T_STRING_LIT        {type.setPrimitive(true);type.setPrimitiveType(TIPO_LITERAL);}
  | T_INT_LIT           {type.setPrimitive(true);type.setPrimitiveType(TIPO_INTEIRO);}
  | T_REAL_LIT          {type.setPrimitive(true);type.setPrimitiveType(TIPO_REAL);}
  | T_CARAC_LIT         {type.setPrimitive(true);type.setPrimitiveType(TIPO_CARACTERE);}
  | T_KW_VERDADEIRO     {type.setPrimitive(true);type.setPrimitiveType(TIPO_LOGICO);}
  | T_KW_FALSO          {type.setPrimitive(true);type.setPrimitiveType(TIPO_LOGICO);}
  ;


func_proto
{
  Funcao   f;
  pair<int, list<RefPortugolAST> > argsp;
  pair< pair<int, list<int> >, list<RefPortugolAST> > argsm;
}
  : #(id:T_IDENTIFICADOR
      {
        f.setId(id);
      }

      (
          argsp=primitivo {f.addParams(argsp);}
        | argsm=matriz    {f.addParams(argsm);}
      )*

      ret_type[f]
      {evaluator.declareFunction(f);}
    )
  ;

func_decl
{
  pair<int, list<RefPortugolAST> > argsp;
  pair< pair<int, list<int> >, list<RefPortugolAST> > argsm;
//   Funcao   f;
}
  : #(id:T_IDENTIFICADOR
      {
        evaluator.setCurrentScope(id->getText());
//         f.setId(id);
      }

      (
          argsp=primitivo /*{f.addParams(argsp);}*/
        | argsm=matriz    /*{f.addParams(argsm);}*/
      )* 

      {
        if((_t != antlr::nullAST) && (_t->getType() == TI_FRETURN)) {
          _t = _t->getNextSibling();
        }
      }
//       ret_type[f]
//         {evaluator.declareFunction(f);}
      (variaveis)?
      inicio
    )

    {evaluator.setCurrentScope(SymbolTable::GlobalScope);}
  ;

ret_type [Funcao& f]
{
  int pt;
  pair<int, list<int> > mt;
}
  : #(TI_FRETURN
//       (
          pt=tipo_prim {f.setReturnType(pt);}
//         | #(TI_VAR_MATRIX mt=tipo_matriz)  {f.setReturnType(mt);}
//       )
    )
  | /*empty*/ {f.setReturnType(TIPO_NULO);/*void*/}
  ;
exception
catch[antlr::NoViableAltException&e] {
  //
}