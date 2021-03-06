#ifndef SUBROUTINE_H
#define SUBROUTINE_H

#include <string>
#include <vector>

#include "Options.hpp"

#include <antlr/LLkParser.hpp>
#include "PortugolParserTokenTypes.hpp"

#include "TextFile.hpp"

using namespace std;

class Type;

class Subroutine
{
public:
	Subroutine(Options *options, const string &name);
	~Subroutine();
	void init();
	void finish();
	void emitPUSHMn(const string &symbol, const bool &pushType = false);
	void emit(const string &mn, const string &op1 = "", const string &op2 = "", const string &op3 = "");
	void emitMnWithPrefix(const string &mn, const string &var, const string &op1 = "", const string &op2 = "");

	void emitLabel(const string &label);

	void emitAsmCode(const string &code);

//	void write(string value);
//	void writeln(string value = "");

	const string& getName() const
	{
		return _name;
	}
	void emitVarDefinition(const string &name, Type* type);
	void emitParDefinition(const string &name, Type* type);
	string getCode() const;

  string declareTmp(Type* type);
private:
	string getMnWithPrefix(const string &mn, const string &var);
	Options *_options;
	vector<string> _params;
	int _lastSourceLine;
	string _name;
  int    _tmpSuffix;
	TextFile _header;
  TextFile _prologue;
	TextFile _body;
	TextFile _footer;
};

#endif

