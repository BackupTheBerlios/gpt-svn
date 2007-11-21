#include "CSymbolTable.hpp"


CSymbolTable::CSymbolTable()
{
}


CSymbolTable::~CSymbolTable()
{
}


CSymbol* CSymbolTable::addProcedure (const std::string &name, const int &type, const int &address, const bool &hasVarArguments, const int &staticParameters, std::vector<CSymbol> parameters)
{
   CSymbol *symbol = new CSymbol( name, type, address, hasVarArguments, staticParameters, parameters);

   _symbols.push_back(symbol);

   // Endereço 0123 (code), procedure, sem retorno, nome "p1",
   // sem argumentos variáveis, 2 parâmetros fixos, p1 (int) e p2 (string)
   // 0024: 0123 P N 2 "p1" N 2 I 4 2 "p1" S 30 2 "p2"
   _data.writeInt( address );
   _data.writeByte( CSymbol::PROC ); // procedure
   _data.writeByte( type ); // tipo do retorno // TODO: em asm proc tem retorno ???
   _data.writeString( name ); // nome da procedure
   _data.writeBool( hasVarArguments );
   _data.writeByte( staticParameters );
   // TODO: falta argumentos

   return symbol;
}


CSymbol* CSymbolTable::addParameter (const std::string &name, const int &type, const int &address)
{
   CSymbol *symbol = new CSymbol( name, type, CSymbol::PARAM, address);

   _symbols.push_back(symbol);

   //_data += symbol->getBinary();

   return symbol;
}


CSymbol* CSymbolTable::addConstant (const std::string &name, const int &type, const int &address)
{
   CSymbol *symbol = new CSymbol( name, type, CSymbol::CONST, address);

   _symbols.push_back(symbol);

   // Endereço 0000 (data), constante, string, 8 bytes ???, nome "c1"
   // 0000: 0000 C S 8??? 2 "c1"
   _data.writeInt( address );
   _data.writeByte( CSymbol::CONST ); // categoria: constante
   _data.writeByte( type );           // tipo
   _data.writeString( name );         // nome da constante

   return symbol;
}


CSymbol* CSymbolTable::add(CSymbol *symbol)
{
//   std::cout << "Adicionando simbolo [" << symbol->getName() << "] type [" << symbol->getType() << "] address [" << symbol->getAddress() << "] a SymbolTable" << std::endl;

   return CSymbolList::add( symbol );
}


bool CSymbolTable::readFromBinary(CBinString &bin)
{
   int size;
   bin.readInt(size);
   for (int count=0; count < size; count++) {
      CSymbol *symbol = new CSymbol();
      symbol->readFromBinary(bin);
      add(symbol);
   }
   return true;
}
