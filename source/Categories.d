module Categories;

/*
	General Category class; All Categories will be objects of this class
*/
class Category {
private:
	string _Name; //name of the category
	string _Color; //color to represent the category
	ushort _Cost_Feriale; //costo per ora in centesimi
	ushort _Cost_Festivo; //costo per ora in centesimi
	static Category[] categories; //list of all categories
	static Category _NoneCategory;  //empty category used when user does not define a category
	static immutable(string[]) colors;
public:
	static Category NoneCategory() {return _NoneCategory; }
	static this () { //initialise static members
		colors = [ "Nero", "Bianco", "Blu", "Rosso", "Verde", "Giallo", "Arancione", "Viola"];
		_NoneCategory = new Category("None");
	}
	this(const string  name, const ushort feriale =0, const ushort  festivo =0, const string  color="Nero") { //constructor
		this.changeName(name); //check and change name
		this.changeColor(color); //check and change color
		this._Cost_Feriale = feriale;
		this._Cost_Festivo = festivo;
		categories ~= this;
	}
	
	//delete a category
	static void deleteCategory(const string nameID) {
		import std.algorithm: remove; 
		size_t index =0;
		for( ; index < categories.length; ++index ){
			if(categories[index].name == nameID) {
				categories = categories.remove(index);
				return ;
			}
		}
		
		throw new Exception("cannot delete a category which does not exists");
	}
	
	//name
	const(string) name() const { return _Name; }
	void changeName (const string name) { 
		import std.algorithm: filter;
		if (! categories.filter!( cat => cat.name == name).empty) {//there is another category with the same name
			throw new Exception("This name is already assigned to another category");
		}
		this._Name = name;
	}
	
	//color
	const(string) color() const { return _Color;}
	void changeColor(const string color) {
		import std.algorithm: filter;
		if(colors.filter!(c => c == color).empty) { //this color is not allowed
			throw new Exception("This color is not in the list of possible colors");
		}
		this._Color = color;	
	}
	
	//costo feriale
	const(ushort) costoFeriale() const {return _Cost_Feriale;}
	void changeCostoFeriale(const ushort costo) {
		this._Cost_Feriale = costo;
	}
	
	//costo festivo
	const(ushort) costoFestivo() const {return _Cost_Festivo;}
	void changeCostoFestivo(const ushort costo){
		this._Cost_Festivo = costo;
	}
	
	//get list of categories; the result will be const when using Local
	static Category[] getCategories() {
		return categories;
	}
	
	static void resetCategories() {
		categories = [_NoneCategory];
	}
	
	static const(string[]) getColors() {
		return colors.dup;
	}
}