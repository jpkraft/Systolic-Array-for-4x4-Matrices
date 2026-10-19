/**
 * reference_model.cpp
 *
 * 4x4 Output-Stationary Systolic Array Matrix Multiplier
 *
 * Patrick Kraft
 * jpkraft@umich.edu
 *
 * C++ model for the array. It creates random test matrices then multiplies them in software to get the correct answers and writes everything into the hex files. The Verilog testbench reads these files and feeds the matrices to the circuit and then checks that the circuit's results match the right answers.
 *
 * Usage: ./reference_model [seed]
 */

#include <fstream>
#include <iomanip>
#include <iostream>
#include <random>
#include <string>

using namespace std;

// Must match ARRAY_SIZE in the Verilog files
const int ARRAY_SIZE = 4;

// Must match NUM_TESTS in tb_systolic_array_4x4.v
const int NUM_TESTS = 10;

// Largest value that fits in an 8-bit input
const int MAX_VALUE = 255;

// Hex digits needed for an 8-bit input and a 32-bit result
const int DATA_HEX_DIGITS = 2;
const int RESULT_HEX_DIGITS = 8;

const unsigned int DEFAULT_SEED = 183;
const string A_FILE_NAME = "a_matrices.hex";
const string B_FILE_NAME = "b_matrices.hex";
const string EXPECTED_FILE_NAME = "expected_results.hex";

/**
 * Requires: nothing
 * Modifies: matrix, generator
 * Effects:  Fills matrix with random values from 0 to MAX_VALUE.
 */
void fillRandomMatrix(int matrix[ARRAY_SIZE][ARRAY_SIZE],
                      mt19937& generator);

/**
 * Requires: nothing
 * Modifies: result
 * Effects:  Sets result to the matrix product a * b.
 */
void multiplyMatrices(const int a[ARRAY_SIZE][ARRAY_SIZE],
                      const int b[ARRAY_SIZE][ARRAY_SIZE],
                      int result[ARRAY_SIZE][ARRAY_SIZE]);

/**
 * Requires: outFile is open, and numDigits is large enough to hold every
 *           value in matrix.
 * Modifies: outFile
 * Effects:  Writes a comment line labeling the test, then each value in
 *           matrix in row-major order, one per line, as a zero-padded hex
 *           number with numDigits digits.
 */
void writeMatrix(ofstream& outFile, const int matrix[ARRAY_SIZE][ARRAY_SIZE],
                 int numDigits, int testNum);

int main(int argc, char* argv[]) {
    unsigned int seed = DEFAULT_SEED;
    if (argc > 1) {
        seed = stoul(argv[1]);
    }

    mt19937 generator(seed);
    ofstream aFile(A_FILE_NAME);
    ofstream bFile(B_FILE_NAME);
    ofstream expectedFile(EXPECTED_FILE_NAME);

    if (!aFile.is_open() || !bFile.is_open() || !expectedFile.is_open()) {
        cout << "Error: could not open the output files." << endl;
    } else {
        int matrixA[ARRAY_SIZE][ARRAY_SIZE] = {};
        int matrixB[ARRAY_SIZE][ARRAY_SIZE] = {};
        int matrixC[ARRAY_SIZE][ARRAY_SIZE] = {};

        for (int testNum = 0; testNum < NUM_TESTS; testNum++) {
            fillRandomMatrix(matrixA, generator);
            fillRandomMatrix(matrixB, generator);
            multiplyMatrices(matrixA, matrixB, matrixC);

            writeMatrix(aFile, matrixA, DATA_HEX_DIGITS, testNum);
            writeMatrix(bFile, matrixB, DATA_HEX_DIGITS, testNum);
            writeMatrix(expectedFile, matrixC, RESULT_HEX_DIGITS, testNum);
        }

        cout << "Wrote " << NUM_TESTS << " test cases using seed "
             << seed << "." << endl;
    }

    return 0;
}

void fillRandomMatrix(int matrix[ARRAY_SIZE][ARRAY_SIZE],
                      mt19937& generator) {
    uniform_int_distribution<int> distribution(0, MAX_VALUE);

    for (int row = 0; row < ARRAY_SIZE; row++) {
        for (int col = 0; col < ARRAY_SIZE; col++) {
            matrix[row][col] = distribution(generator);
        }
    }
}

void multiplyMatrices(const int a[ARRAY_SIZE][ARRAY_SIZE],
                      const int b[ARRAY_SIZE][ARRAY_SIZE],
                      int result[ARRAY_SIZE][ARRAY_SIZE]) {
    for (int i = 0; i < ARRAY_SIZE; i++) {
        for (int j = 0; j < ARRAY_SIZE; j++) {
            int sum = 0;
            for (int k = 0; k < ARRAY_SIZE; k++) {
                sum += a[i][k] * b[k][j];
            }
            result[i][j] = sum;
        }
    }
}

void writeMatrix(ofstream& outFile, const int matrix[ARRAY_SIZE][ARRAY_SIZE],
                 int numDigits, int testNum) {
    outFile << "// test " << dec << testNum << endl;

    for (int row = 0; row < ARRAY_SIZE; row++) {
        for (int col = 0; col < ARRAY_SIZE; col++) {
            outFile << hex << setw(numDigits) << setfill('0')
                    << matrix[row][col] << endl;
        }
    }
}
