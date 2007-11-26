
#include "BaseSemanticWalker.hpp"
#include "PortugolTokenTypes.hpp"
#include "SymbolTable.hpp"
#include "Symbol.hpp"
#include "Types.hpp"
#include "SymbolTableExceptions.hpp"

#include <iostream>

BaseSemanticWalker::BaseSemanticWalker(SymbolTable* symtable)
 : antlr::TreeParser(), _symtable(symtable) {}

void BaseSemanticWalker::useLib(const  std::string& lib) {
  //TODO: sanitize lib: "bla\ bla" -> "bla bla"

  std::cerr << "Using lib:" << lib << std::endl;
}

void BaseSemanticWalker::declare(const IDList& idlist,
                                 Type* type,
                                 bool isConst) {

  try {
    IDList::const_iterator it;
    for (it = idlist.begin(); it != idlist.end(); ++it) {
      _symtable->declare(_symtable->newSymbol(
            (*it)->getText(), type, (*it)->getLine(), isConst));
    }
  } catch (RedeclarationException e) {
    cerr << "catched! Redeclaration: " << e.symbol().toString() <<"\n";
  }
}

void BaseSemanticWalker::defineStruct(const std::string& name,
                                      const SymbolList& fieldList,
                                      int line) {

  try {
    _symtable->defineStruct(name, fieldList, line);
  } catch (RedefinedTypeException e) {
    cerr << "catched! Redefined type: " << e.typeName() << "\n";
  } catch (RedeclarationException e) {
    cerr << "catched! Redeclaration: " << e.symbol().toString() << "\n";
  }
}

void BaseSemanticWalker::declareProc(const std::string& name,
                                     const SymbolList& params,
                                     int line,
                                     Type* ret) {

  SubprogramType* type = new SubprogramType(
        params.toTypeList(),
        (ret == 0) ? _symtable->getType(PortugolTokenTypes::T_NULO) : ret);

  try {
    _symtable->declare(_symtable->newSymbol(name, type,line));
    _symtable->declare(params, name);
  } catch (RedeclarationException e) {
    cerr << "catched! Redeclaration: " << e.symbol().toString() << std::endl;
    delete type;
  }
}

Type* BaseSemanticWalker::getType(const std::string& name) {
  try {
    return _symtable->getType(name);
  } catch (UndeclaredTypeException e) {
    std::cerr << "catched! Undeclared type: " << e.typeName() << std::endl;
    return _symtable->getType(PortugolTokenTypes::T_NULO);
  }
}

Type* BaseSemanticWalker::getType(int id) {
  try {
    return _symtable->getType(id);
  } catch (UndeclaredTypeException e) {
    std::cerr << "catched! Undeclared type: " << id << std::endl;
    return _symtable->getType(PortugolTokenTypes::T_NULO);
  }
}

Type* BaseSemanticWalker::getSymbolType(const std::string& name) {
  try {
    return _symtable->getSymbol(name).type();
  } catch (UndeclaredSymbolException e) {
    std::cerr << "catched! Undeclared symbol: " << e.lexeme() << std::endl;
    return _symtable->getType(PortugolTokenTypes::T_NULO);
  }
}

Type* BaseSemanticWalker::evalFCall(const std::string& fname,
                                   const TypeList& paramTypes) {
  //TODO
  //-proibicao de consts passados para parametros "ref" sem constness

// - Testar avaliacao de chamada de subprogramas (com e sem reticencias)
//   -Avaliacao de qtd e tipos de parametros
}

void BaseSemanticWalker::evalMatrixSubscript(Type* type) {
  //TODO
}

  //TODO
  //-proibicao de consts como lvalues em expressoes

void BaseSemanticWalker::evalAttribution(Type* ltype, Type* rtype) {
  if (!ltype->isLValueFor(rtype)) {
    std::cerr << "ilegal: "
              << ltype->name() << " := " << rtype->name() << endl;
  }
}

void BaseSemanticWalker::evalAttribution(Type* ltype, const InitMatrixList& mtx) {
  Type* rtype = evalHomogeneity(mtx);
  if (!ltype->isLValueFor(rtype)) {
    std::cerr << "ilegal: "
              << ltype->name() << " := " << rtype->name() << endl;
  }
}

void BaseSemanticWalker::evalAttribution(Type* ltype, const InitStructList& stc) {
  StructType* rtype = createAnonymousStructFor(stc);

  if (!ltype->isLValueFor(rtype)) {
    std::cerr << "ilegal: "
              << ltype->name() << " := " << rtype->name() << endl;
  }
}

StructType* BaseSemanticWalker::createAnonymousStructFor(const InitStructList& stc) {
  SymbolList slist;
  InitStructList::const_iterator it;
  for (it = stc.begin(); it != stc.end(); ++it) {
    slist.push_back(_symtable->newSymbol(it->first, it->second));
  }

  return _symtable->createAnonymousStruct(slist);
}

Type* BaseSemanticWalker::evalHomogeneity(const InitMatrixList& mtx) {
  InitMatrixList::const_iterator it;
  int dim = 0;
  Type* type = 0;
  for (it = mtx.begin(); it != mtx.end(); ++it) {
    if (dim == 0) {
      dim = it->first;
    } else if (dim != it->first) {
      std::cerr << "err: Numero variavel de dimensoes na matriz!\n";
    }

    if (type == 0) {
      type = it->second;
    } else if (!type->equals(it->second)) {
      std::cerr << "err: Numero variavel de tipos na matriz!\n";
    }
  }
  return _symtable->retrieveMatrixType(type, dim);
}


Type*
BaseSemanticWalker::evalExpr_OU(Type* left, Type* right) {
  return _symtable->getType(PortugolTokenTypes::T_LOGICO);
}

Type*
BaseSemanticWalker::evalExpr_E(Type* left, Type* right) {
  return _symtable->getType(PortugolTokenTypes::T_LOGICO);
}


Type*
BaseSemanticWalker::evalExpr_BIT_OU(Type* left, Type* right) {
  if (left->equals(PortugolTokenTypes::T_INTEIRO) &&
      right->equals(PortugolTokenTypes::T_INTEIRO)) {
    return _symtable->getType(PortugolTokenTypes::T_INTEIRO);
  } else {
    std::cerr << "ilegal: "
              << left->name() << " | " << right->name() << std::endl;
    return _symtable->getType(PortugolTokenTypes::T_NULO);
  }
}


Type*
BaseSemanticWalker::evalExpr_BIT_OUX(Type* left, Type* right) {
  if (left->equals(PortugolTokenTypes::T_INTEIRO) &&
      right->equals(PortugolTokenTypes::T_INTEIRO)) {
    return _symtable->getType(PortugolTokenTypes::T_INTEIRO);
  } else {
    std::cerr << "ilegal: "
              << left->name() << " ^ " << right->name() << std::endl;
    return _symtable->getType(PortugolTokenTypes::T_NULO);
  }
}


Type*
BaseSemanticWalker::evalExpr_BIT_E(Type* left, Type* right) {
  if (left->equals(PortugolTokenTypes::T_INTEIRO) &&
      right->equals(PortugolTokenTypes::T_INTEIRO)) {
    return _symtable->getType(PortugolTokenTypes::T_INTEIRO);
  } else {
    std::cerr << "ilegal: "
              << left->name() << " & " << right->name() << std::endl;
    return _symtable->getType(PortugolTokenTypes::T_NULO);
  }
}


Type*
BaseSemanticWalker::evalExpr_IGUAL(Type* left, Type* right) {
  if (left->equals(right)) {
    _symtable->getType(PortugolTokenTypes::T_LOGICO);
  } else {
    std::cerr << "ilegal: "
              << left->name() << " = " << right->name() << std::endl;
    return _symtable->getType(PortugolTokenTypes::T_NULO);
  }
}


Type*
BaseSemanticWalker::evalExpr_DIFERENTE(Type* left, Type* right) {
  if (left->equals(right)) {
    _symtable->getType(PortugolTokenTypes::T_LOGICO);
  } else {
    std::cerr << "ilegal: "
              << left->name() << " <> " << right->name() << std::endl;
    return _symtable->getType(PortugolTokenTypes::T_NULO);
  }
}


Type*
BaseSemanticWalker::evalExpr_MAIOR(Type* left, Type* right) {
  if ((left->isPrimitive() && right->isPrimitive()) &&
      (left->equals(right) || left->numPromotionWith(right))) {
    _symtable->getType(PortugolTokenTypes::T_LOGICO);
  } else {
    std::cerr << "ilegal: "
              << left->name() << " > " << right->name() << std::endl;
    return _symtable->getType(PortugolTokenTypes::T_NULO);
  }
}


Type*
BaseSemanticWalker::evalExpr_MENOR(Type* left, Type* right) {
  if ((left->isPrimitive() && right->isPrimitive()) &&
      (left->equals(right) || left->numPromotionWith(right))) {
    _symtable->getType(PortugolTokenTypes::T_LOGICO);
  } else {
    std::cerr << "ilegal: "
              << left->name() << " < " << right->name() << std::endl;
    return _symtable->getType(PortugolTokenTypes::T_NULO);
  }
}


Type*
BaseSemanticWalker::evalExpr_MAIOR_EQ(Type* left, Type* right) {
  if ((left->isPrimitive() && right->isPrimitive()) &&
      (left->equals(right) || left->numPromotionWith(right))) {
    _symtable->getType(PortugolTokenTypes::T_LOGICO);
  } else {
    std::cerr << "ilegal: "
              << left->name() << " >= " << right->name() << std::endl;
    return _symtable->getType(PortugolTokenTypes::T_NULO);
  }
}



Type*
BaseSemanticWalker::evalExpr_MENOR_EQ(Type* left, Type* right) {
  if ((left->isPrimitive() && right->isPrimitive()) &&
      (left->equals(right) || left->numPromotionWith(right))) {
    _symtable->getType(PortugolTokenTypes::T_LOGICO);
  } else {
    std::cerr << "ilegal: "
              << left->name() << " <= " << right->name() << std::endl;
    return _symtable->getType(PortugolTokenTypes::T_NULO);
  }
}


Type*
BaseSemanticWalker::evalExpr_BIT_SHIFT_LEFT(Type* left, Type* right) {
  if (left->equals(PortugolTokenTypes::T_INTEIRO) &&
      right->equals(PortugolTokenTypes::T_INTEIRO)) {
    return _symtable->getType(PortugolTokenTypes::T_INTEIRO);
  } else {
    std::cerr << "ilegal: "
              << left->name() << " << " << right->name() << std::endl;
    return _symtable->getType(PortugolTokenTypes::T_NULO);
  }
}


Type*
BaseSemanticWalker::evalExpr_BIT_SHIFT_RIGHT(Type* left, Type* right) {
  if (left->equals(PortugolTokenTypes::T_INTEIRO) &&
      right->equals(PortugolTokenTypes::T_INTEIRO)) {
    return _symtable->getType(PortugolTokenTypes::T_INTEIRO);
  } else {
    std::cerr << "ilegal: "
              << left->name() << " >> " << right->name() << std::endl;
    return _symtable->getType(PortugolTokenTypes::T_NULO);
  }
}


Type*
BaseSemanticWalker::evalExpr_MAIS(Type* left, Type* right) {
  Type* ret;
  if (ret = left->numPromotionWith(right)) {
    return ret;
  } else if (ret = left->litPromotionWith(right)) {
    return ret;
  } else {
    std::cerr << "ilegal: "
              << left->name() << " + " << right->name() << std::endl;
    return _symtable->getType(PortugolTokenTypes::T_NULO);
  }
}


Type*
BaseSemanticWalker::evalExpr_MENOS(Type* left, Type* right) {
  Type* ret;
  if (ret = left->numPromotionWith(right)) {
    return ret;
  } else {
    std::cerr << "ilegal: "
              << left->name() << " - " << right->name() << std::endl;
    return _symtable->getType(PortugolTokenTypes::T_NULO);
  }
}


Type*
BaseSemanticWalker::evalExpr_DIV(Type* left, Type* right) {
  Type* ret;
  if (ret = left->numPromotionWith(right)) {
    return ret;
  } else {
    std::cerr << "ilegal: "
              << left->name() << " / " << right->name() << std::endl;
    return _symtable->getType(PortugolTokenTypes::T_NULO);
  }
}


Type*
BaseSemanticWalker::evalExpr_MULTIP(Type* left, Type* right) {
  Type* ret;
  if (ret = left->numPromotionWith(right)) {
    return ret;
  } else {
    std::cerr << "ilegal: "
              << left->name() << " * " << right->name() << std::endl;
    return _symtable->getType(PortugolTokenTypes::T_NULO);
  }
}


Type*
BaseSemanticWalker::evalExpr_MOD(Type* left, Type* right) {
  if (left->equals(PortugolTokenTypes::T_INTEIRO) &&
      right->equals(PortugolTokenTypes::T_INTEIRO)) {
    return _symtable->getType(PortugolTokenTypes::T_INTEIRO);
  } else {
    std::cerr << "ilegal: "
              << left->name() << " % " << right->name() << std::endl;
    return _symtable->getType(PortugolTokenTypes::T_NULO);
  }
}



Type*
BaseSemanticWalker::evalExpr_UN_NEGATIVO(Type* left) {
  if (left->equals(PortugolTokenTypes::T_INTEIRO) ||
      left->equals(PortugolTokenTypes::T_REAL)) {
    return left;
  } else {
    std::cerr << "ilegal: "
              << " - " << left->name() << std::endl;
    return _symtable->getType(PortugolTokenTypes::T_NULO);
  }
}


Type*
BaseSemanticWalker::evalExpr_UN_POSITIVO(Type* left) {
  if (left->equals(PortugolTokenTypes::T_INTEIRO) ||
      left->equals(PortugolTokenTypes::T_REAL)) {
    return left;
  } else {
    std::cerr << "ilegal: "
              << " + " << left->name() << std::endl;
    return _symtable->getType(PortugolTokenTypes::T_NULO);
  }
}


Type*
BaseSemanticWalker::evalExpr_NAO(Type* left) {
  return _symtable->getType(PortugolTokenTypes::T_LOGICO);
}


Type*
BaseSemanticWalker::evalExpr_BIT_NAO(Type* left) {
  if (left->equals(PortugolTokenTypes::T_INTEIRO)) {
    return _symtable->getType(PortugolTokenTypes::T_INTEIRO);
  } else {
    std::cerr << "ilegal: "
              << " ~ " << left->name() << std::endl;
    return _symtable->getType(PortugolTokenTypes::T_NULO);
  }
}

