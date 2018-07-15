module ServerSide;

import vibe.db.mongo.mongo;

class SyncServer {

static:

	MongoClient _mongoClient;
	
	
	void connect (const string host, const string user , const string password ) {
	
		_mongoClient = connectMongoDB("mongodb://"~ user ~":"~ password~ host ~ "/?ssl=true&sslverifycertificate=false");
		
	}
	




}