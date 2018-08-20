module LogIn;

/*
	This module handles all info about users, roles and passwords.
	The info are all stored locally. To sync this info with the server ServerSide should be used
*/

import Utility;

class Login {
	
	import std.json; //file is written as a JSON
	
static:

	private immutable(string[]) roles  = ["Admin", "User"];

	private string _role = ""; //user role
	private string _user = null;
	private ubyte[20] scramSHA1(const ubyte[] salt, const string data, const uint limit = 10000) {
		/*
			This is an implementation of SCRAM-SHA-1; At the bottom of the file there is a commment explaining the methods
			this function should return StoredKey; i, password and salt should be inputs 
			SaltedPassword  := Hi(Normalize(password), salt, i)
			ClientKey       := HMAC(SaltedPassword, "Client Key")
			StoredKey       := H(ClientKey)
		*/
		import std.digest.sha: SHA1, sha1Of;
		import std.digest.hmac: hmac, HMAC;
		import std.string: representation;
		
		ubyte[4] initializer = [0,0,0,1];
		
		immutable(ubyte[]) pass = data.representation;
		ubyte[20] U = hmac!SHA1( (salt ~initializer), pass); //compute U1 = HMAC(pass, salt + INT(1))
		ubyte[20] SaltedPassword = U;
		auto mac = HMAC!SHA1(pass);
		
		for(uint i = 1; i< limit; ++i) { //at iteration i it computes Ui
			mac.start();
			mac.put(U);
			U = mac.finish(); //Ui = HMAC(pass, Ui-1)
			foreach( j; 0 .. 20) {
				SaltedPassword[j] = SaltedPassword[j]^U[j];
			}
			
		}
		//at this point SaltedPassword = Hlimit(Normalize(password), salt, limit)
		
		ubyte[20] ClientKey = "Client Key".representation.hmac!SHA1(SaltedPassword);
		
		ubyte[20] StoredKey = sha1Of(ClientKey);
		
		return StoredKey;
	}
	
	//read password file
	private const(string) readPassFile() {
		import std.file: readText, exists, isFile;
		//check on the local file; Local should ensure that the file is there: download from server
		auto path = getCurrentPath()~"pass"; //path of local password file
		if(!exists(path)) {
			throw new PassFileException("Local password file does not exists. Please sync with server");
		}
		if(!path.isFile) {
			throw new PassFileException("Local password file seems to be corrupted.");
		}
		auto fileContent = readText(path); //read local file
		return fileContent;
	}
	//write to password file
	private void writePassFile(const string buffer) {
		import std.file: write, exists, isFile;
		//check on the local file; Local should ensure that the file is there: download from server
		auto path = getCurrentPath()~"pass"; //path of local password file
		if(!exists(path)) {
			throw new PassFileException("Local password file does not exists. Please sync with server");
		}
		if(!path.isFile) {
			throw new PassFileException("Local password file seems to be corrupted.");
		}
		path.write(buffer);
	}
	//replace old password with new one on the password file
	private void replacePassword(const string user, const string newPassword) {
		string password = hashPassword(user, newPassword); //create hash password
		
		// let's check if user was admin; if so we need to set this in new Password to say so
		auto fileContent = readPassFile();
		JSONValue file = parseJSON(fileContent);
		
		//now write password in the file;
		import std.array : replace;
		auto newContent = fileContent.replace(file[user]["pwd"].str,password);
		writePassFile(newContent); 
	}

	//get methods
	const(string) getUser() { return _user; }
	const(bool) isAdmin() { return _role == "Admin";}
	const(string[]) getUsers() {
		string[] result;
		foreach( ref s; jsonEntries(readPassFile)) {
			if(s != "_id") result ~= s;
		}
		
		return result;
	}
	
	//create hash of the password; this is what should be stored in files
	const(string) hashPassword(const string userName, const string password) {
		
		import std.digest.sha: sha1Of;
		import std.base64;
		
		/*
			salt is SHA-1(userName)
		*/
		
		auto salt =  sha1Of(userName);
		return Base64.encode(scramSHA1(salt, password));
		
	}
	const(string) hashRole(const string userName, const string role) {
		import std.digest.sha: sha1Of;
		import std.base64;
		
		/*
			salt is SHA-1(userName~secret)
		*/
		string secret = "w5L./9Eh-?sw!eZ"; //if you don't know this you can't generate a correct hash of the role
		auto salt =  sha1Of(userName~secret);
		return Base64.encode(scramSHA1(salt, role, 20000));
	}
	
	
	//log out
	void logout() {
		_role = "";
		_user = null;
	}
	
	//log in
	void login(const string user, const string password) {
		import std.stdio;
		
		auto fileContent = readPassFile();
		
		JSONValue file = parseJSON(fileContent);
		//user should be in the file since in Local we check that user is actually a user
		
		string filepass = file[user]["pwd"].str; //get password

		if(filepass != hashPassword(user ,password)) {
			throw new PasswordException("login failed; passwords do not match; please sync to check the local file is up to date");
		}

		_user = user;
		_role = null;
		foreach (ref role; roles) {
			if(file[user]["role"].str == hashRole(user,role)) {
				_role = role;
				writeln("########################## role is : " , _role);
			}
		}
		
		if( _role is null) {
			throw new PassFileException("Cannot find role which matches the hash on the pass file. Maybe the file is corrupted");
		}
	}
	
	//change own old password
	void changePassword ( const string newPassword) {
		
		replacePassword(_user, newPassword);
		//now local should sync
	}
	
	//set new password if you forgot; need to be admin
	void forgotPassword (const string user, const string newPassword){
		//Local needs to ensure that password file contains user's information to change the password
		if(isAdmin() == false) {
			throw new PermissionException("you need to be an admin to reset a forgotten password");
		}
		
		replacePassword(user, newPassword);
		//now local should sync
	}
	
	//create user- pass
	void createUser( const string user , const string password, const string role = "User") {
		
		if(isAdmin == false) {
			throw new PermissionException("need to be admin to create user");
		}
		import std.algorithm: filter;
		import std.range: empty;
		if( ! getUsers.filter!(x => x == user).empty) {
			throw new Exception("user already exists");
		}
		auto hash = hashPassword(user, password);
		auto roleHash = hashRole(user,role);
		auto fileContent = readPassFile();
		
		JSONValue json = parseJSON(fileContent);
		json.object[user] = (`{ "role": "`~roleHash~`", "pwd" : "` ~hash~`"}`).parseJSON; //add pair user : hash to the json
		
		writePassFile(json.toPrettyString);
		
	}
	
	void deleteUser (const string user) {

		//if the user does not exists locally, this function does nothing
		
		if(user == _user ) {
			throw new Exception("cannot delete the current user");
		}
		
		if(isAdmin() == false) {
			throw new PermissionException("need to be admin to delete users");
		}
		
		auto fileContent = readPassFile; //get content of the password file
		
		JSONValue json = parseJSON(fileContent);
		
		json.object.remove(user);
		
		writePassFile(json.toPrettyString);
		
	}
	
	//change user role
	void changeRole(const string user, const string newRole) {
		if(_role != "Admin") {
			throw new PermissionException("Need to be admin to change roles");
		}
		
		auto file = readPassFile.parseJSON;
		
		file[user]["role"] = hashRole(user,newRole);
		
		writePassFile(file.toPrettyString);
	}
	
	//get implemented roles
	const(string[]) getRoles() { return roles.dup; }
	
	//get user role
	const(string) getUserRole() {
		return _role;
	}
	
	//get role of a user
	const(string) getUserRole(const string user) {
		auto content = parseJSON(readPassFile());
		string roleHash = content[user]["role"].str;
		foreach( ref r; roles ) {
			if( hashRole(user, r) == roleHash)
				return r;
		}
		
		throw new Exception("cannot find role of given user");
	}
	
}

class PasswordException : Exception {
	const(string) message;
	this(string msg, string file = __FILE__, size_t line = __LINE__ ) { //constructor needs a message, and possible where the error is 
		message = msg;
		super(msg,file, line); //call constructor of Exception class
	}
}

class PassFileException : Exception {
	const(string) message;
	this(string msg, string file = __FILE__, size_t line = __LINE__ ) { //constructor needs a message, and possible where the error is 
		message = msg;
		super(msg,file, line); //call constructor of Exception class
	}
}

class PermissionException: Exception {
	const(string) message;
	this(string msg, string file = __FILE__, size_t line = __LINE__ ) { //constructor needs a message, and possible where the error is 
		message = msg;
		super(msg,file, line); //call constructor of Exception class
	}
}



/*
USING SCRAM-SHA-1 as the MongoDB does;

MongoDB stores this info:

{ 
	"_id" : "officeManager.puci",
	"user" : "puci",
	"db" : "officeManager",
	"credentials" : { 
		"SCRAM-SHA-1" : { 
			"iterationCount" : 10000,
			"salt" : "sGTiovNDIMgbRalYe11BYg==",
			"storedKey" : "T7xxFgkjW3bE8Z7z2p784Y5WC5w=",
			"serverKey" : "SKdpPhBrddx++JGs6HAajnhwWRY="
		},
		"SCRAM-SHA-256" : { 
			"iterationCount" : 15000,
			"salt" : "xsa2vVO5TaUNKN6Fn+DtHcrhUoy6AXhqZ97eqQ==",
			"storedKey" : "VDValFFtxv7DnDjKHayT5p4m79I8O1znG/rrdX63g+s=",
			"serverKey" : "m220abV7rQKKUjUt2Qtwnp74iVUQHi0lqvbsauuVufQ="
		}
	},
	"roles" : [ { "role" : "officeManagerAdmin", "db" : "officeManager" } ]
}


SCRAM Explanation:

SaltedPassword  := Hi(Normalize(password), salt, i)
ClientKey       := HMAC(SaltedPassword, "Client Key")
StoredKey       := H(ClientKey)
AuthMessage     := client-first-message-bare + "," +
                    server-first-message + "," +
                    client-final-message-without-proof
ClientSignature := HMAC(StoredKey, AuthMessage)
ClientProof     := ClientKey XOR ClientSignature
ServerKey       := HMAC(SaltedPassword, "Server Key")
ServerSignature := HMAC(ServerKey, AuthMessage)

where

Normalize(str): Apply the SASLprep profile [RFC4013] of the
      "stringprep" algorithm [RFC3454] as the normalization algorithm to
      a UTF-8 [RFC3629] encoded "str".  The resulting string is also in
      UTF-8.  When applying SASLprep, "str" is treated as a "stored
      strings", which means that unassigned Unicode codepoints are
      prohibited (see Section 7 of [RFC3454]).  Note that
      implementations MUST either implement SASLprep or disallow use of
      non US-ASCII Unicode codepoints in "str".

HMAC(key, str): Apply the HMAC keyed hash algorithm (defined in
      [RFC2104]) using the octet string represented by "key" as the key
      and the octet string "str" as the input string.  The size of the
      result is the hash result size for the hash function in use.  For
      example, it is 20 octets for SHA-1 (see [RFC3174]).
      
H(str): Apply the cryptographic hash function to the octet string
      "str", producing an octet string as a result.  The size of the
      result depends on the hash result size for the hash function in
      use.
      
Hi(str, salt, i):

     U1   := HMAC(str, salt + INT(1))
     U2   := HMAC(str, U1)
     ...
     Ui-1 := HMAC(str, Ui-2)
     Ui   := HMAC(str, Ui-1)

     Hi := U1 XOR U2 XOR ... XOR Ui

      where "i" is the iteration count, "+" is the string concatenation
      operator, and INT(g) is a 4-octet encoding of the integer g, most
      significant octet first.

      Hi() is, essentially, PBKDF2 [RFC2898] with HMAC() as the
      pseudorandom function (PRF) and with dkLen == output length of
      HMAC() == output length of H().



HMAC explained

	H = hash function
	B = byte-length of block input for H
	K = key zero padded to reach length B;
		if too long apply H and then zero pad
	text = data
 	ipad = the byte 0x36 repeated B times
	opad = the byte 0x5C repeated B times.

	HMAC = H(K XOR opad + H(K XOR ipad + text))


*/
