module Crypt;
import std.stdio;
import std.format: format;
import std.base64;

string AESencrypt(const string password, const string plaintext) {
	auto aes = new AES(password);
	return aes.encrypt(plaintext);
}

string AESdecrypt(const string password, const string ciphertext) {
	auto aes = new AES(password);
	return aes.decrypt(ciphertext); 
}

void test() {
	auto aes = new AES("jfhGd32-");
	aes.test();
}

private class AES {

	private {
		ubyte[240] expandedKey;
		static immutable ubyte[256] Sbox = [
		0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
  		0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
  		0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
  		0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
  		0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
  		0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
  		0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
  		0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
  		0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
  		0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
  		0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
  		0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
  		0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
 		0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
 		0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
  		0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16 ];
	
		static immutable ubyte[256] invSbox = [
		0x52, 0x09, 0x6a, 0xd5, 0x30, 0x36, 0xa5, 0x38, 0xbf, 0x40, 0xa3, 0x9e, 0x81, 0xf3, 0xd7, 0xfb,
  		0x7c, 0xe3, 0x39, 0x82, 0x9b, 0x2f, 0xff, 0x87, 0x34, 0x8e, 0x43, 0x44, 0xc4, 0xde, 0xe9, 0xcb,
  		0x54, 0x7b, 0x94, 0x32, 0xa6, 0xc2, 0x23, 0x3d, 0xee, 0x4c, 0x95, 0x0b, 0x42, 0xfa, 0xc3, 0x4e,
  		0x08, 0x2e, 0xa1, 0x66, 0x28, 0xd9, 0x24, 0xb2, 0x76, 0x5b, 0xa2, 0x49, 0x6d, 0x8b, 0xd1, 0x25,
  		0x72, 0xf8, 0xf6, 0x64, 0x86, 0x68, 0x98, 0x16, 0xd4, 0xa4, 0x5c, 0xcc, 0x5d, 0x65, 0xb6, 0x92,
  		0x6c, 0x70, 0x48, 0x50, 0xfd, 0xed, 0xb9, 0xda, 0x5e, 0x15, 0x46, 0x57, 0xa7, 0x8d, 0x9d, 0x84,
  		0x90, 0xd8, 0xab, 0x00, 0x8c, 0xbc, 0xd3, 0x0a, 0xf7, 0xe4, 0x58, 0x05, 0xb8, 0xb3, 0x45, 0x06,
  		0xd0, 0x2c, 0x1e, 0x8f, 0xca, 0x3f, 0x0f, 0x02, 0xc1, 0xaf, 0xbd, 0x03, 0x01, 0x13, 0x8a, 0x6b,
  		0x3a, 0x91, 0x11, 0x41, 0x4f, 0x67, 0xdc, 0xea, 0x97, 0xf2, 0xcf, 0xce, 0xf0, 0xb4, 0xe6, 0x73,
 		0x96, 0xac, 0x74, 0x22, 0xe7, 0xad, 0x35, 0x85, 0xe2, 0xf9, 0x37, 0xe8, 0x1c, 0x75, 0xdf, 0x6e,
 		0x47, 0xf1, 0x1a, 0x71, 0x1d, 0x29, 0xc5, 0x89, 0x6f, 0xb7, 0x62, 0x0e, 0xaa, 0x18, 0xbe, 0x1b,
  		0xfc, 0x56, 0x3e, 0x4b, 0xc6, 0xd2, 0x79, 0x20, 0x9a, 0xdb, 0xc0, 0xfe, 0x78, 0xcd, 0x5a, 0xf4,
  		0x1f, 0xdd, 0xa8, 0x33, 0x88, 0x07, 0xc7, 0x31, 0xb1, 0x12, 0x10, 0x59, 0x27, 0x80, 0xec, 0x5f,
  		0x60, 0x51, 0x7f, 0xa9, 0x19, 0xb5, 0x4a, 0x0d, 0x2d, 0xe5, 0x7a, 0x9f, 0x93, 0xc9, 0x9c, 0xef,
  		0xa0, 0xe0, 0x3b, 0x4d, 0xae, 0x2a, 0xf5, 0xb0, 0xc8, 0xeb, 0xbb, 0x3c, 0x83, 0x53, 0x99, 0x61,
  		0x17, 0x2b, 0x04, 0x7e, 0xba, 0x77, 0xd6, 0x26, 0xe1, 0x69, 0x14, 0x63, 0x55, 0x21, 0x0c, 0x7d ];
  		
	}
	
	private void expandKey(const string password) {
	
		import std.digest.sha: sha256Of;
		ubyte[32] key = sha256Of(password); //password should be 32 byte long; so I hash it to that length
		//key is what AES considers as the password
		immutable ubyte[8] rc = [0x01,0x02,0x04,0x08,0x10,0x20,0x40,0x80]; //round constant
		
		expandedKey = new ubyte[240];//result
		
		for(int word=0; word<60; ++word) { //a word is a vector of 4 bytes
			if(word < 8){ //copy the key
				expandedKey[4*word] = key[4*word];
				expandedKey[4*word+1] = key[4*word+1];
				expandedKey[4*word+2] = key[4*word+2];
				expandedKey[4*word+3] = key[4*word+3];
			} else if (word % 8 == 0) {
				ubyte[4] w = new ubyte[4]; //a word which will undergo modifications
				
				//get previous word
				for(int i=0; i< 4; ++i){
					w[i] = expandedKey[4*(word-1)+i]; //copy previous word
				}
				
				//apply Sbox
				for(int i=0; i<4; ++i) {
					w[i] = Sbox[cast(int)(w[i])];
				}
				
				//rotate to left
				ubyte b = w[0];
				for(int i =0; i<3; ++i){
					w[i] = w[i+1];
				}
				w[3]=b;
				
				//add round constant [rc(word/8 -1) 0x00, 0x00, 0x00]
				w[0] = w[0] ^ rc[(word/8)-1];
				//other xor are useless since a xor 0x00 = a
				
				//add word (word-8)
				for(int i=0; i< 4; ++i){
					w[i] = w[i]^expandedKey[4*(word-8)+i];
				}
				
				//now w is the word^th word so copy it into the result
				for(int i=0; i<4; ++i) {
					expandedKey[4*word+i] = w[i];
				}
			} else if(word % 8 == 4) {
				ubyte[4] w = new ubyte[4];
				
				//get previous word
				for(int i=0; i< 4; ++i){
					w[i] = expandedKey[4*(word-1)+i];
				}
				
				//apply Sbox
				for(int i=0; i<4; ++i) {
					w[i] = Sbox[cast(int)(w[i])];
				}
				
				//add the (word-8)^th word
				for(int i=0; i<4; ++i){
					w[i] = w[i]^expandedKey[4*(word-8)+i];
				}
				
				//copy back to key
				for(int i=0; i<4; ++i){
					expandedKey[4*word+i] = w[i];
				}
			} else {
			
				//add previous word to (word-8)
				for(int i =0; i<4; ++i){
					expandedKey[4*word+i] = expandedKey[4*(word-1)+i]^expandedKey[4*(word-8)+i];
				}
			
			}

		}//end loop word
		
	}//end expasion key
	
	private void addRoundKey(ref ubyte[16] block, const int round) {
		for(int i =0; i<16; ++i){
			block[i] = block[i]^expandedKey[round*16+i]; //add key to block
		}
	}
	
	private void subBytes(ref ubyte[16] block) {
		for(int i=0; i< 16; ++i) {
			block[i] = Sbox[cast(int)(block[i])];//apply Sbox to each byte
		}
	}
	
	private void invSubBytes(ref ubyte[16] block) {
		for(int i=0; i<16; ++i) {
			block[i] = invSbox[cast(int)(block[i])];
		}
	}
	
	private void shiftRows(ref ubyte[16] block) {
	
		//row 0 not touched
		
		//row 1 shift left by 1
		ubyte b = block[4];
		for(int i =0; i <3; ++i) {
			block[4+i] = block[5+i];//shift bytes block[4..8) to the left by one
		}
		block[7] = b;
		
		//row 2 shift left by 2
		b = block[8];
		block[8] = block[10]; block[10]= b; //swap 2 blocks
		b = block[9];
		block[9] = block[11]; block[11] = b; //swap 2 blocks
		
		//row 3 shift left by 3
		b = block[15];
		for(int i =0; i<3; ++i){
			block[15-i] = block[14-i]; //shift bytes block[12..16) to the right by 1
		}
		block[12] = b;
	}
	
	private void invShiftRows(ref ubyte[16] block) {
		
		//row 0 not touched
	
		//row 1 shift right by 1
		ubyte b = block[7];
		for(int i=0; i<3; ++i){
			block[7-i] = block[6-i];
		}
		block[4] = b;
		
		//row 2 shift right by 2
		b = block[8];
		block[8] = block[10]; block[10]= b; //swap 2 blocks
		b = block[9];
		block[9] = block[11]; block[11] = b; //swap 2 blocks
		
		//row 4 shift right by 3
		b = block[12];
		for(int i=0; i<3; ++i) {
			block[12+i] = block[13+i];
		}
		block[15] = b;
	}
	
	private ubyte mult(int n)(const ubyte b) {
		//multiply b by n
		//b is seen as a polynomial with coefficients modulo 2
		//operations are modulo x^8+x^4+x^3+x+1
		//so x^8  is 0x1b (coefficient are modulo 2)
		ubyte result = b;
		final switch (n) {
		
			case 2:
				bool x7 = (b & 0x80) != 0; //(0x80 is 1000 0000; so b&0x80 is 1000 0000  or 0000 0000)
				//x7 is ture iff b has x^7 as its term
				//multiplication by 0x02 is multiplication by 0000 0010 which is x
				result = cast(ubyte)(b << 1); //multiply by 2
				if( x7) { // then x^8 is 0x1b
					result = result ^0x1b;
				}
				return result;
			case 3: //0x03 = 0x02 ^ 0x01
				return mult!2(b) ^ b; 
			case 4: //0x04 is x^2 so we need to multiply by x 2 times
				return mult!2(mult!2(b));
			case 8: //0x08 is x^3 so we need to multiply by x 3 times
				return mult!2(mult!4(b));
			case 9: //0x09 = 0x08 ^ 0x01
				return mult!8(b) ^ b;
			case 11: //0x0b = 0x08 ^ 0x02 ^ 0x01
				return mult!8(b) ^ mult!2(b) ^ b;
			case 13: //0x0d = 0x08 ^ 0x04 ^ 0x01
				return mult!8(b) ^ mult!4(b) ^ b;
			case 14: //0x0e = 0x08 ^ 0x04 ^ 0x02
				return mult!8(b) ^ mult!4(b) ^ mult!2(b);
		}
	}
	
	private void mixColumns(ref ubyte[16] block) {
		//multiply each column by a matrix
		//sum is xor 
		//multiplication is modulo x^8+x^4+x^3+x+1 (which is the binary number 0001 0001 1011)
		//so x^8 is 0x1b
		/*	2 3 1 1
			1 2 3 1
			1 1 2 3
			3 1 1 2
		*/
		for(int col =0; col < 4; ++col) {
			ubyte[4] a = new ubyte[4]; //a vector which will by multiplied by the matrix
			for(int i =0; i<4; ++i) {
				a[i] = block[col+4*i];
			}
			//writeBytes(a);
			block[col] = mult!2(a[0]) ^ mult!3(a[1]) ^ a[2] ^ a[3];
			block[col+4] = a[0] ^ mult!2(a[1]) ^ mult!3(a[2]) ^ a[3];
			block[col+8] = a[0] ^ a[1] ^ mult!2(a[2]) ^ mult!3(a[3]);
			block[col+12] = mult!3(a[0]) ^ a[1] ^ a[2] ^ mult!2(a[3]);
			//writeBytes([block[col], block[col+4], block[col+8], block[col+12]]);
		}
	}
	
	private void invMixColumns(ref ubyte[16] block) {
		//multiply by the inverse matrix
		//sum is xor
		//multiplication is modulo x^8+x^4+x^3+x+1 (which is the binary number 0001 0001 1011)
		//so x^8 is 0x1b
		/*
			14 11 13  9
			 9 14 11 13
			13  9 14 11	
			11 13  9 14
		*/
		for(int col =0; col < 4; ++col) {
			ubyte[4] a = new ubyte[4]; //a vector which will by multiplied by the matrix
			for(int i =0; i<4; ++i) {
				a[i] = block[col+4*i];
			}
			//writeBytes(a);
			block[col] = mult!14(a[0]) ^ mult!11(a[1]) ^ mult!13(a[2]) ^ mult!9(a[3]);
			block[col+4] = mult!9(a[0]) ^ mult!14(a[1]) ^ mult!11(a[2]) ^ mult!13(a[3]);
			block[col+8] = mult!13(a[0]) ^ mult!9(a[1]) ^ mult!14(a[2]) ^ mult!11(a[3]);
			block[col+12] = mult!11(a[0]) ^ mult!13(a[1]) ^ mult!9(a[2]) ^ mult!14(a[3]);
			//writeBytes([block[col], block[col+4], block[col+8], block[col+12]]);
		}
	
	}
	
	private void encryptBlock(ref ubyte[16] block) {
	
		addRoundKey(block, 0);
		for(int i =0; i <13; ++i) {
			subBytes(block);
			shiftRows(block);
			mixColumns(block);
			addRoundKey(block,i+1);
		}
		subBytes(block);
		shiftRows(block);
		addRoundKey(block,14);
	}
	
	private void decryptBlock(ref ubyte[16] block){
	
		addRoundKey(block,14); //inverse of addRoundKey is the same
		invShiftRows(block);
		invSubBytes(block);
		for(int i= 12; i>=0; --i){
			addRoundKey(block, i+1);
			invMixColumns(block);
			invShiftRows(block);
			invSubBytes(block);
		}
		addRoundKey(block,0);
	}
	
	this( const string password) {
		expandKey(password);
	}
	
	string encrypt(const string plaintext) {
		ulong bytes = plaintext.length; //n° of bytes in the input
		const ushort pad = 16 - (bytes % 16); //pad to apply (always put 1)
		bytes += pad; //bytes should be a multiple of 16 (always add padding)
		assert(bytes % 16 == 0);
		//writeln("bytes to encrypt: ",bytes);
		//writeln("pad: ", pad);
		//writeln("pad byte: ", cast(ubyte)pad);
		const ulong blocks = bytes / 16; //n° of blocks in the input
		ubyte[] data = new ubyte[bytes];
		for(int i=0; i<bytes; ++i){
			if(i<plaintext.length) data[i] = cast(ubyte) (plaintext[i]);
			else data[i] = cast(ubyte) pad;
		}
		//writeln("data: ", data);
		assert(data.length %16 == 0);
		
		ubyte[] result = new ubyte[bytes];
		
		ubyte[16] vector = new ubyte[16];//vector to use in the cbc mode
		vector = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16];
		//writeln("now start to encrypt blocks");
		for(ulong blockN = 0; blockN < blocks; ++blockN) { //for each block
			ubyte[16] block = new ubyte[16]; //single block
			for(int i =0; i< 16; ++i) { //copy values in the block
				block[i] = data[blockN*16+i];
			}
			//writeln("block ",blockN+1, " copied");
			//now block is the block to encrypt in the cbc mode
			for(int i =0; i<16; ++i) {
				block[i] = block[i]^vector[i]; //xor vector
			}
			//writeln("vector added");
			//writeln("block before: ", block);
			encryptBlock(block); //encrypt single block
			//writeln("block after: ", block);
			//writeln("block encrypted");
			//now block is the encrypted block
			for(int i =0; i< 16; ++i) {
				result[blockN*16+i] = block[i]; //copy block into result
				vector[i] = block[i]; // block is next iteration's vector
			}
			//writeln("done block ", blockN+1);
		}
	
		string cipher = Base64.encode(result); //result is now UTF-8
		return cipher;
	}
	
	string decrypt(const string ciphertext){
	
		//first decode from base64
		ubyte[] input = Base64.decode(ciphertext);
		const ulong bytes = input.length;
		//writeln("bytes to decrypt: ",bytes);
		
		ubyte[] data = new ubyte[bytes];
		for(int i=0; i<bytes; ++i){
			data[i] = input[i]; //data to descrypt
		}
		
		const ulong blocks = bytes / 16; //n° of blocks 
	
		ubyte[] result = new ubyte[bytes];
		
		ubyte[16] vector = new ubyte[16]; //vector to use in cbc mode
		vector = [0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f,0x10];
		//writeln("vector: ", vector);
		//writeln("start decrypting");
		for(int blockN =0; blockN < blocks; ++blockN){
			ubyte[16] block = new ubyte[16]; //single block
			for(int i=0; i<16; ++i){
				block[i] = data[blockN*16+i];
			}
			//writeln("block ",blockN+1, " copied");
			//writeln("block before: ", block);
			decryptBlock(block);
			
			//now block is decrypted
			//writeln("block decrypted");
			for(int i=0; i<16; ++i){
				result[blockN*16+i] = block[i]^vector[i]; //plain text is decrypted xor vector
				vector[i] = data[blockN*16+i]; //next vector is what was the block before decryption
			}
			//writeln("block after: ", block);
			//writeln("done block ", blockN+1);
		}
		
		//writeln("plaintext with padding: ", cast(string)(result));
		//now remove padding
		ushort pad = cast(int) (result[bytes-1]); //there is always some pad
		//writeln("pad to remove: ", pad);
		if(pad > 16) {
			throw new Exception("decrypting not worked well; probably wrong password");
		}
		return ( cast(string)(result[0 .. $ - pad]) );
	}
	
	private void writeBytes(ubyte[] bs) {
		write("block: [ "~format("0x%02x",bs[0]));
		for(int i =1; i<bs.length; ++i){
			write(", "~format("0x%02x",bs[i]));
		}
		write(" ]\n");
	}
	
	void test(){
		
		ubyte[16] block = [0xdb, 0xf2, 0x01, 0xc6, 0x13, 0x0a, 0x01, 0xc6, 0x53, 0x22, 0x01, 0xc6, 0x45, 0x5c, 0x01, 0xc6];
		
		writeln("addRoundKey");
		writeBytes(block);
		addRoundKey(block, 3);
		writeBytes(block);
		addRoundKey(block,3);
		writeBytes(block);
		writeln("=========================================================================");
		writeln("subBytes");
		writeBytes(block);
		subBytes(block);
		writeBytes(block);
		invSubBytes(block);
		writeBytes(block);
		writeln("=========================================================================");
		writeln("shiftRows");
		writeBytes(block);
		shiftRows(block);
		writeBytes(block);
		invShiftRows(block);
		writeBytes(block);
		writeln("=========================================================================");
		writeln("mixColumns");
		writeBytes(block);
		mixColumns(block);
		writeBytes(block);
		invMixColumns(block);
		writeBytes(block);
		writeln("=========================================================================");
		writeln("encrypt/decrypt block");
		writeBytes(block);
		encryptBlock(block);
		writeBytes(block);
		decryptBlock(block);
		writeBytes(block);
		writeln("=========================================================================");
		writeln("encrypt/decrypt all");
		writeBytes(block);
		string str = encrypt(cast(string)(block));
		writeBytes(cast(ubyte[])str);
		str = decrypt(str);
		writeBytes(cast(ubyte[])str);
		writeln("=========================================================================");
		
	
	}

}