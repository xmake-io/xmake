import person;
import <iostream>;
import <string>;  // For operator<< for std::string

using namespace std;

int main()
{
	Person person{ "Kole", "Webb" };
	cout << person.getLastName() << ", " << person.getFirstName() << endl;
}
