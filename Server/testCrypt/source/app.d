import std.stdio;
import Crypt;

void main()
{
	const string plaintext = "prova qualcosa a asndakns dasndiajn21312.asd0";
	const string password = "123miasdmIHN1..";
	writeln("plaintext: ", plaintext);
	string cipher = AESencrypt(password,plaintext);
	writeln("cipher: ", cipher);
	writeln("decrypted: ", AESdecrypt(password,cipher));
	writeln("decrypted wrong password: ", AESdecrypt("12asdasfnjdnd",cipher));
}
