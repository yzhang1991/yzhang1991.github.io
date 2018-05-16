#include <iostream>
#include "ArgumentManager.h"
int main(int argc, char *argv[]) {
    ArgumentManager am(argc, argv);
    string fileNameForMatrixA = am.get("A");
    string fileNameForMatrixC = am.get("C");
    cout << "File name for matrix A: " << fileNameForMatrixA << endl
         << "File name for matrix C: " << fileNameForMatrixC << endl;
    return 0;
}
