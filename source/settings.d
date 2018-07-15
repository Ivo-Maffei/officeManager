module Settings;

/*
import std.datetime.date : Date, DayOfWeek;
import Utility;

class Impostazioni {

static:

	private Date[] festività; //Natale, Pasqua, etc... (only the current year) & user-defined
	private DayOfWeek[] festivoSettimanale; //Domenica, forse Sabato; 
	private Date currentDate;
	private bool singleTimer;
	private DayOfWeek stringToDayOfWeek(const string dayString) {
		DayOfWeek day;
		switch (dayString) {
			case "mon": 
				day = DayOfWeek.mon;
				break;
			case "tue":
				day = DayOfWeek.tue;
				break;
			case "wed":
				day = DayOfWeek.wed;
				break;
			case "thu":
				day = DayOfWeek.thu;
				break;
			case "fri":
				day = DayOfWeek.fri;
				break;
			case "sat":
				day = DayOfWeek.sat;
				break;
			case "sun":
				day = DayOfWeek.sun;
				break;
			default:
				throw new Exception("I cannot understand which day you mean. Use a string of length 3");
		}
		return day;
	}
	
	//get current date and set standard stuff
	static this() {
	
		//get current date
		import std.datetime.systime: Clock;
		auto now = Clock.currTime();
		currentDate= cast(Date)(now);
	
		//read settings from file
		import std.file: readText;
		import std.json;
		import std.conv: to;
		
		string saveFilePath = getCurrentPath() ~"save";
		JSONValue filejson = saveFilePath.readText.parseJSON; //get JSON from file
		
		singleTimer = filejson["singleTimer"].type == JSON_TYPE.TRUE; //get boolean
		
		//get festivo settimanale
		auto days = filejson["festivoSettimanale"].array;//this is an array of JSONValue
		foreach(ref d; days) {
			festivoSettimanale ~= to!(DayOfWeek)(d.integer);
		}
		
		auto fest = filejson["festività"].array; //this is an array of JSONValue
		if( currentDate.year != Date.fromISOExtString(fest[0].str).year) { //festività sono quelle dell'anno scorso
			//update festività
		
		
		}
		foreach(ref s ; fest) {
			festività ~= Date.fromISOExtString(s.str);
		}
		
		
	}
	
	// tells if the given date is a bank holiday[or day-off from the week]
	const(bool) isFeriale(const Date date = currentDate) {
		return !isFestivo(date) ;
		
	}
	const(bool) isFeriale(const string stringDate) {
		//date should be in the format yyyy-mm-dd
		Date date = Date.fromISOExtString(stringDate);
		return isFeriale(date);
	}

	//tells if the give date is a bank holiday or week festivo
	const(bool) isFestivo(const Date date = currentDate) { 
		//Date ensures the date is valid
		if(date.year != currentDate.year) {
			//need to check with apple calendar
		}
		
		foreach (ref fest; festività) {
			if( fest == date) return true;
		}
		
		foreach (ref day; festivoSettimanale) {
			if( date.dayOfWeek == day) return true;
		}
		
		return false;
	}
	const(bool) isFestivo(const string stringDate) {
		//string should be of the form yyyy-mm-dd
		Date date= Date.fromISOExtString(stringDate);
		return isFestivo(date);
	}
	
	//set a new festività
	void setFestività(const Date date) {
		foreach (ref day; festività) {
			if( day == date) return ; //it's already a festività
		}
		
		festività ~= date;
	}
	void setFestività(const string stringDate) {
		Date date = Date.fromISOExtString(stringDate);
		setFestività(date);
	}
	
	//remove a festività
	void removeFestività(const Date date) {
		size_t index =0;
		for (; index<festività.length; ++index){
			if(festività[index] == date) break;
		}
		
		if(index == festività.length) {
			throw new Exception("trying to delete a festività which is not there");
		}
		
		import std.algorithm: remove;
		festività = festività.remove(index);
	
	}
	void removeFestività(const string stringdate) {
		Date date = Date.fromISOExtString(stringdate);
		removeFestività(date);
	}
	
	//set new festivoSettimanale
	void setFestivoSettimanale(const DayOfWeek day) {
		foreach( ref d ; festivoSettimanale) {
			if( d == day) return ; //already there
		}
		
		festivoSettimanale ~= day;
	}
	void setFestivoSettimanale(const string dayString) {
		DayOfWeek day = stringToDayOfWeek(dayString);
		setFestivoSettimanale(day);
	}
	
	//remove festivoSettimanale
	void removeFestivoSettimanale(const DayOfWeek day) {
		size_t index=0;
		for(; index < festivoSettimanale.length; ++index) {
			if(festivoSettimanale[index] == day) break;
		}
		
		if(index == festivoSettimanale.length) {
			throw new Exception("cannot delete a day which is not there");
		}
		
		import std.algorithm: remove;
		festivoSettimanale = festivoSettimanale.remove(index);
	
	}
	void removeFestivoSettimanale(const string dayString) {
		DayOfWeek day = stringToDayOfWeek(dayString);
		removeFestivoSettimanale(day);
	}
	
	//get singleTimer
	const(bool) isSingleTimer() {return singleTimer; }
	
	//set single timer
	void setSingleTimer (const bool flag) {
		singleTimer = flag;
	}
	
	//sync festività con apple calendar
	void syncWithAppleCalendar() {
	
	}

	//save state of the object into a file
	void saveImpostazioni() {
		import std.json; //file is in JSON format
		
		//create JSON and add all things to remember
		JSONValue filejson = parseJSON("{}");
		string[] fest; //create list of strings to represent Date[]
		foreach (ref date; festività) {
			fest ~= date.toISOExtString;
		}
		filejson.object["festività"] = JSONValue(fest);
		filejson.object["festivoSettimanale"] = JSONValue(festivoSettimanale);
		filejson.object["singleTimer"] = JSONValue(singleTimer);

		string saveFilepath = getCurrentPath() ~"save";
		
		import std.file: write;
		
		saveFilepath.write(filejson.toPrettyString);
	}

}

*/