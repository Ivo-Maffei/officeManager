module LogIn;

import Utility;

class Login {
	
	import std.json; //file is written as a JSON
	
static:

	private bool _admin = false; //is logged user admin?
	private string _user = null;
	//create hash of the password; this is what should be stored in files
	private const(string) hashPassword(const string user, const string password) {
		//use idea <user, h(g(user)|| password)>; g = ripemd160; h = sha-512 100 rounds;
		import std.digest.sha: sha512Of, toHexString;
		import std.digest.ripemd: ripemd160Of;
		import std.string: representation;
		
		ubyte[20] salt = ripemd160Of(user);
		ubyte[64] pass = sha512Of(salt ~ representation(password));  //representation returns immutable(ubyte)[]
		foreach (i ; 0..99) { //iterate 99 times
			pass = sha512Of(pass);
		}
		
		return pass.toHexString.dup;
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
		password = addAdminToPassword(password, file[user].str[$-1] == 'A');
		
		//now write password in the file;
		import std.array : replace;
		auto newContent = fileContent.replace(file[user].str,password);
		writePassFile(newContent); 
	}
	private const(string) addAdminToPassword (const string password, const bool admin ) {
		if (admin) return password ~ 'A';
		
		import std.random: Random, unpredictableSeed, uniform;
		
		auto randomGenerator = Random(unpredictableSeed);
		
		size_t index = uniform(0 ,password.length, randomGenerator);
		char l = password[index];
		if( l == 'A') l= 'B';
		return password ~ l;
	}
	
	const(string) getUser() { return _user; }
	const(bool) isAdmin() { return _admin;}
	
	//log out
	void logout() {
		_admin = false;
		_user = null;
	}
	
	//log in
	void login(const string user, const string password) {
		
		auto fileContent = readPassFile();
		
		JSONValue file = parseJSON(fileContent);
		//user should be in the file since in Local we check that user is actually a user
		
		string filepass = file[user].str; //get whole string
		char admin = filepass[$-1]; //get admin character
		filepass = filepass[0..$-1]; //remove last character
	
		auto input= hashPassword(user, password);
		//check that passwords match
		if(filepass != input) { //if login fails
			throw new PasswordException("login failed; passwords do not match; please sync to check the local file is up to date");
		}
		
		_user = user;
		_admin = admin == 'A';
	}
	
	//change old password
	void changePassword ( const string oldPassword, const string newPassword, const string user=_user) {
		
		if(user != _user && _admin == false) {
			throw new PermissionException("to change password of another user, you need to be admin");
		}
		
		//Local should ensure that the password file is updated
		auto oldHash =  hashPassword(user, oldPassword);
		
		auto fileContent = readPassFile();
		JSONValue file = parseJSON(fileContent);
		if( oldHash != file[user].str[0..$-1]) {
			throw new PasswordException("old password seems to be incorrect");
		}
		
		//if we reach this point, then oldPassword is correct.
		replacePassword(user, newPassword);
		//now local should sync
	}
	
	//set new password if you forgot; need to be admin
	void forgotPassword (const string user, const string newPassword){
		//Local needs to ensure that password file contains user's information to change the password
		if(_admin == false) {
			throw new PermissionException("you need to be an admin to reset a forgotten password");
		}
		
		replacePassword(user, newPassword);
		//now local should sync
	}
	
	//create user- pass
	void createUser( const string user , const string password, const bool admin = false) {
		
		if(_admin == false) {
			throw new PermissionException("need to be admin to create user");
		}
		
		//Local should check user is unique [need sync to do so]
		
		auto hash = addAdminToPassword(hashPassword(user, password),admin);
		auto fileContent = readPassFile();
		
		JSONValue json = parseJSON(fileContent);
		json.object[user] = JSONValue(hash); //add pair user : hash to the json
		
		writePassFile(json.toPrettyString);
		
	}
	
	void deleteUser (const string user) {

		//if the user does not exists locally, this function does nothing
		
		if(user == _user ) {
			throw new Exception("cannot delete the current user");
		}
		
		if(_admin == false) {
			throw new PermissionException("need to be admin to delete users");
		}
		
		auto fileContent = readPassFile; //get content of the password file
		
		JSONValue json = parseJSON(fileContent);
		
		json.object.remove(user);
		
		writePassFile(json.toPrettyString);
		
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
