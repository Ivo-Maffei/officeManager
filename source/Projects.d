module Projects;

import Categories;
import std.stdio;
//Implementation constraint; you cannot create ex-novo 2 projects at the same time (hsec precision), since ID must be unique

/*
	General Project class; Any project will be an object of such class
*/
class Project {

private:
	string _shortName; //name of the project
	ushort _jobNumber; //job number [this will be part of the name]; Do I need to keep it as a separate variable??
	bool _sync;
	ulong _ID =0;  //unique ID to identify the project
	static Project[] projects = new Project[0]; //list of all projects
	
	string createName(string name, ushort number) const {  //helper function that builds the name given a string and job number
		import std.conv: to;
		import std.range: take;
		string snumber = to!string(number);
		snumber = to!string("00000".take(5-snumber.length)) ~ snumber;
		return ("[" ~ snumber ~ "] - " ~ name);
	}
	
	bool uniqueName(const string attempt) const { //helper function to check whether the name of the project is unique
		import std.algorithm: filter; 
		
		return projects.filter!(proj => (proj.name == attempt && proj.ID != this._ID)).empty;
	}
	
public:

	string note; //any note that the user may add 
	
	this( const string name,const ushort number=0, const bool syncCalendar = false, const string notes ="", const ulong id=0) { //constructor

		if (number > 99999) { //force project number to be less than 6 digits
			throw new Exception("creating project with JobNumber too big");
		}
		
		string attempt = createName(name,number);
		if (!uniqueName(attempt)) { //check uniqueness of the name
			throw new Exception("Project name is not unique");
		}
		
		this._shortName = name; //build name and assign it
		this._jobNumber = number; //assign jobNumber
		
		this.note = notes; //assign notes
		
		if( id ==0 ) { //if no id is provided; create one using timestamp
			import std.datetime.systime; 
			
			changeID (Clock.currTime.stdTime); //seconds since 1/01/01 UTC; timestamp to ensure uniqueness
		} else {
			changeID(id);
		}
		
		_sync = syncCalendar;
		
		projects ~= this;
		
	}
	
	//delete a project
	static void deleteProject(const ulong projID) {
		import std.algorithm : remove;
		size_t index=0;
		for(; index<projects.length; ++index) {
			if(projects[index].ID == projID ) {
				projects = projects.remove(index);
				return;
			}
		}
		throw new Exception("cannot find project to delete");
	} 
	
	//name
	const(string) name() const { return createName(_shortName, _jobNumber);}
	void changeName(const string name) {
		string attempt = createName(name,this._jobNumber);
		if (!uniqueName(attempt)) {
			throw new Exception("Project name is already used");
		}
		this._shortName= name;
	}
	
	//job number	
	const(ushort) jobNumber() const { return _jobNumber;}
	void changeJobNumber( const ushort number) {
		string attempt = createName(this._shortName,number);
		if (!uniqueName(attempt)) {
			throw new Exception("Project number is not unique");
		}
		this._jobNumber = number;
	}
	
	//ID should be really carefull when changing ID
	const(ulong) ID() const { return _ID; }
	void changeID (const ulong ID) {
		import std.algorithm : filter;
		if (!projects.filter!(proj => proj.ID == ID).empty) {
			throw new Exception("Project ID is not unique");
		}
		_ID = ID;
	}
	
	//get list of projects [the list is not const; user should use the Local call, so that it is constant]
	static Project[] getProjects() {
		return projects;
	}
	
	//get shortName
	const(string) shortName() const {return this._shortName; }
	
	//get set sync
	const(bool) sync() const {return this._sync; }
	void changeSync(const bool sync) {
		this._sync = sync;
	}
	
	static void resetProjects() {
		projects = [];
	}
	
}
