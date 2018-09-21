import std.stdio;
import std.socket;
import std.concurrency;

void main()
{
	sequentialTest();
	
}

void test(const string message, const string id = ""){

	//create socket
	writeln("#### "~id~" creating socket");
	auto address = getAddress("79.2.254.77",27018)[0];
	Socket server = new Socket(address.addressFamily, SocketType.STREAM, ProtocolType.TCP);
	server.blocking = true;
	writeln("#### "~id~" connecting socket");
	server.connect(address);
	writeln("#### "~id~" socket created and connected");

	server.send(message);
	writeln("#### "~id~" send message: ", message);
	auto buffer = new char[2048];
	auto bytes = server.receive(buffer);
	writeln("#### "~id~" received ", bytes, " bytes");
	writeln("#### "~id~" message received: ",buffer[0 .. bytes]);

}

void sequentialTest() {
	writeln("#### start sequential test");
	
	writeln("#### test: register device");
	test("puci:1234@registerDevice@testDevice@FA25BFDD-9F57-4393-A302-4B7E33C9D67F");
	writeln("##########################");
	
	writeln("#### test: get projects");
	test("puci:id:FA25BFDD-9F57-4393-A302-4B7E33C9D67F@get@projects");
	writeln("##########################");
	
	writeln("#### test: get categories");
	test("puci:id:FA25BFDD-9F57-4393-A302-4B7E33C9D67F@get@categories");
	writeln("##########################");
	
	writeln("#### test: new session with 2 sessions");
	test(`puci:id:FA25BFDD-9F57-4393-A302-4B7E33C9D67F@newSession@{
    "_id": 636723674178855850,
    "archived": false,
    "category": "dummyCat",
    "dateTime": "2018-09-12T18:43:37",
    "description": "prova edit Line",
    "duration": "00:01",
    "place": "",
    "project": 636715825106398270,
    "status": "new",
    "tantum": false,
    "user": "puci"
}
{
    "_id": 636723674506124880,
    "archived": false,
    "category": "dummyCat",
    "dateTime": "2018-09-12T18:44:10",
    "description": "",
    "duration": "00:00",
    "place": "",
    "project": 636715825106398270,
    "status": "new",
    "tantum": false,
    "user": "puci"
}
`);
	writeln("##########################");
	
	writeln("#### end sequential test");

}

void worker (const string message, const string id) {
	
	writeln("#### test: "~id);
	test(message,id);
	writeln("#### end test: "~id);
}

void parallelTest() {
	writeln("#### start parallel test");
	
	spawn(&worker, "puci:1234@registerDevice@testDevice@TestDeviceID1234asd", "register device");
	
	spawn(&worker, "puci:id:TestDeviceID1234asd@get@projects", "get projects");
	
	spawn(&worker, "puci:id:TestDeviceID1234asd@get@categories", "get categories");
	
	spawn(&worker, `puci:id:TestDeviceID1234asd@newSession@{
    "_id": 636723674178855850,
    "archived": false,
    "category": "dummyCat",
    "dateTime": "2018-09-12T18:43:37",
    "description": "prova edit Line",
    "duration": "00:01",
    "place": "",
    "project": 636715825106398270,
    "status": "new",
    "tantum": false,
    "user": "puci"
}
{
    "_id": 636723674506124880,
    "archived": false,
    "category": "dummyCat",
    "dateTime": "2018-09-12T18:44:10",
    "description": "",
    "duration": "00:00",
    "place": "",
    "project": 636715825106398270,
    "status": "new",
    "tantum": false,
    "user": "puci"
}
`, "new sessions");

}
