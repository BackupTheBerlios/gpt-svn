#ifndef GPT_BIN_STRING_H
#define GPT_BIN_STRING_H

#include <string>


class CBinString : public std::string
{
public:
   void writeInt(const int &value);
   void writeByte(const char &value);
   void writeString(const std::string &value, const bool &writeSize=true);
   void writeBool(const bool &value);
   void readInt(int &value);
   void readByte(char &value);
   char getByte(const int &pos);
   void getByte(const int &pos, char &value);
   int getInt(int pos);
   void readString(std::string &value);
   std::string readString();
   void readBool(bool &value);
   void setInt(int pos, const int &value);
   void setCString(int pos, const std::string &value);
   void pushInt(const int &value);
   int popInt();
   int getLastInt() const;
   void pushCString(const std::string &value);
   std::string popCString();
   void pushBytes(const int &number);
   void popBytes(const int &number);
   bool removeIfEqual(const int &value);
   bool removeIfEqual(const char &value);
   bool removeIfEqual(const std::string &value);
   std::string getCString(const int &address);
   std::string::find;
};

#endif
