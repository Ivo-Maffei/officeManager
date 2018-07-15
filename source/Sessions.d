module Sessions;

import Categories;
import Projects;

class Session {

private:
	string _dateTime; //start of the session
	string _duration = "00:00"; //hh:mm
	// ushort _cost =0; this for tantums see below
	Category _category; //category of the session
	string _user; //user of the session
	ulong _projID; //project the session belongs to
	ulong _sessionID; //session ID (may be equal to project ID)
	//each session is uniquely defined by its dateTime, project ID and user [no user can create 2 sessions for the same project at the same time]
	bool validID (ulong ID) {
		import std.algorithm: filter;
		if(ID==0) return false; //this is kept for internal use
		return !(Project.getProjects().filter!(pro => pro.ID == ID).empty);
	}
public:
	
	string description; //user notes
	
	this(const ulong projID, const string user, const string description = "", Category category = Category.NoneCategory, const string date = "none", const ulong id=0) {
	
		import std.datetime.systime; 
		import std.range: take; 
		import std.conv;
	
		//get user :this is done by login and password through the program
		
		if(date == "none") { //get current date and time
			auto time = Clock.currTime(); //this is the current local time
			this._dateTime = to!string(time.toISOExtString.take(19)); //get time precision is 1 second (roughly)
		} else {
			this.changeDateTime( date);
		}
	
		this._category = category; //assign category
	
		this.description = description; //assign description
	
		//check that ID actually maps to a Project
		import std.stdio;
		
		if(!validID(projID)) {
			throw new Exception("creating a session with a project ID which does not match any project");
		}
		this._projID = projID;
	
		this._user = user;
	
		if( id ==0 ) { //if no id is provided; create one using timestamp
			import std.datetime.systime; 
		
			changeID (Clock.currTime.stdTime); //seconds since 1/01/01 UTC; timestamp to ensure uniqueness
		} else {
			changeID(id);
		}
	}
	
	//date of start
	const(string) dateTime() const { return _dateTime; }
	void changeDateTime(string date) {
		import std.regex: ctRegex, matchFirst;
		auto expression = ctRegex!(r"\b[0-9][0-9][0-9][0-9]-((0[0-9])|(1[0-2]))-(([0-2][0-9])|30|31)T(([0-1][0-9])|(2[0-4])):[0-5][0-9]:[0-5][0-9]\b");
		auto match = matchFirst(date, expression);
		if(match.empty) { //no match found
			throw new Exception("setting  date and time, which don't match the regex yyyy-mm-ddThh:mm:ss");
		}
		//now check that moth and day make sense
		import std.range: drop, take;
		import std.conv: to;
		string monthDay =to!string( (date.drop(5).take(5))); //month is mm-dd
		int day = to!int(monthDay.drop(3)); //day string
		int month = to!int(monthDay.take(2));
		switch (month) {
			case 2 : 
				if(day >29) {//I'm not checking leap years
					throw new Exception("session is setting a date which does not make sense");
				}
				break;
			case 4,6,9,11:
				if (day > 30) {
					throw new Exception("session is setting a date which does not make sense");
				}
				break;
			default: //do nothing
				break;
		}
		this._dateTime = date;
	}
	
	//duration
	const(string) duration() const { return _duration; }
	void changeDuration(string duration) {
		import std.regex: ctRegex, matchFirst;
		auto expression = ctRegex!(r"\b[0-9][0-9]?:[0-5][0-9]?");
		auto match = matchFirst(duration, expression);
		if(match.empty) { //no match found
			throw new Exception("setting a duration, which doesn't match the regex hh:mm");
		}
		this._duration = duration;
	}
	
	//category
	const(Category) category() const { return _category; }
	void changeCategory (Category category) {
		this._category = category;
	}
	
	//user session
	const(string) user() const { return _user; }
	void changeUser(const string user) { //Only admin
		this._user = user;
	}
	
	//project IDq
	const(ulong) projectID() const {return _projID; }
	void changeProjectID (ulong ID) {
		if(!validID(ID)) {
			throw new Exception("change a session project ID with an ID which does not match any project");
		}
		this._projID = ID;
	}
	
	//id
	const(ulong) ID() const {return _sessionID;}
	void changeID(const ulong id) { //session can't check for uniqueness
		_sessionID = id;
	}

}

class Tantum : Session {

	private ushort _cost; //costo in centesimi
	private bool _taxable;
	
	this(const ulong ID, const string user, const ushort cost =0, bool tax = false, const string description ="", Category category = Category.NoneCategory, const string date = "none", const ulong sessionID =0) {
	
		this._cost = cost; //set the cost
		this._taxable = false;
		super(ID,user,description, category, date, sessionID); //initialize all the over stuff
		
		_duration ="none";
	}
	
	//override to avoid the possibility of changing duration
	final override void changeDuration(string dura) {
		throw new Exception("Tantum cots do not have duration; leave it none");
	}
	
	//cost
	const(ushort) cost() const{return this._cost; }
	void changeCost(const ushort cost) {
		this._cost = cost;
	}
	
	//taxable
	const(bool) taxable() const {return this._taxable;}
	void changeTaxable( const bool tax) {
		this._taxable = tax;
	}

}
