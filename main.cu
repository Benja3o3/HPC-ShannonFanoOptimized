#include <iostream>
#include <stdio.h>
#include <cstdlib>
#include <cuda_runtime.h>
#include <fstream>
#include <time.h>
#include <map>
#include <vector>
#include <algorithm>

using namespace std;

__global__ void kernel() {
    // Código del kernel
}

// __global__ void symbolsFrequencyKernel(char *symbols, int *frecuency, int totalSymbols) {
//     int index = threadIdx.x + blockIdx.x * blockDim.x;
//     if (index < totalSymbols) {
//         atomicAdd(&frecuency[symbols[index]], 1);
//     }
// }

int getTotalSymbols(string path);
map<char,int> symbolsFrequency(string path);
vector<pair<char, int>> sortSymbolsByFrecuency(map<char,int> &frecuency);
map<char, vector<bool>> bitsAssignment(vector<pair<char,int>> &vec);
bool sortByValue(const pair<char, int>& a, const pair<char, int>& b);
void shannonFano(vector<pair<char,int>> &vec, int l, int r, map<char, vector<bool>> &code);
int partition(vector<pair<char,int>> &v, int l, int r, map<char, vector<bool>> &code);

int main(int argc, char **argv) {
    if(argc != 2){
		cout << "Error. Debe ejecutarse como ./main 'data/..' " << endl;
		exit(EXIT_FAILURE);
	}
    string filePath = argv[1];
    //Contar simbolos del texto
    int totalSymbols = getTotalSymbols(filePath);
    cout << "Total de simbolos: " << totalSymbols << endl;

    //Calcular la frecuencia de cada simbolo
    map<char,int> frecuency = symbolsFrequency(filePath);

    //Ordenar por frecuencia (de mayor a menor)
    vector<pair<char, int>> vec = sortSymbolsByFrecuency(frecuency);

    //Asignacion de bits a cada simbolo
    map<char, vector<bool>> code = bitsAssignment(vec);

    // // Definir el número de bloques y el número de hilos por bloque
    // int numBlocks = 1;
    // int threadsPerBlock = 1;

    // // Lanzar el kernel en el dispositivo CUDA
    // kernel<<<numBlocks, threadsPerBlock>>>();

    // // Sincronizar el dispositivo CUDA
    // cudaDeviceSynchronize();

    // // Imprimir mensaje de finalización
    // printf("¡Programa en CUDA ejecutado con éxito!\n");

    return 0;
}

bool sortByValue(const pair<char, int>& a, const pair<char, int>& b) {
    return a.second > b.second; // Ordena por los valores de las cadenas
}

int getTotalSymbols(string path) {
    ifstream file(path);
    if (!file) {
        cout << "No se pudo abrir el archivo." << endl;
        return 1;
    }

    file.seekg(0, ios::end);
    streampos tamano = file.tellg();
    file.seekg(0, ios::beg);

    file.close();
    return tamano;
}

map<char,int> symbolsFrequency(string path){
    map<char,int> frecuency;
    time_t start = clock();
    ifstream file(path);
    if (!file) {
        cout << "No se pudo abrir el archivo." << endl;
        return frecuency;
    }

    char symbol;
    while (file.get(symbol)) {
        if (frecuency.find(symbol) == frecuency.end()) {
            frecuency[symbol] = 1;
        } else {
            frecuency[symbol]++;
        }
    }

    file.close();
    time_t end = clock();
    cout << "Tiempo de calculo de la frecuencia de cada simbolos: " << (double)(end - start) / CLOCKS_PER_SEC << " segundos." << endl;
    return frecuency;
}

void shannonFano(vector<pair<char,int>> &vec, int l, int r, map<char, vector<bool>> &code){
    int p;
    if(l<r){
        p = partition(vec, l, r, code);
        shannonFano(vec, l, p-1, code);
        shannonFano(vec, p, r, code);
    }
}

int partition(vector<pair<char,int>> &v, int l, int r, map<char, vector<bool>> &code){
    // cout << "partition" << endl;
	int maxFrecuency = 0;
	//Se calcula la probabilidad maxima de la particion
	for (int x = l; x <= r ; x++){
		maxFrecuency += v[x].second;
	}
	int i = l; //left pos
	int j = r; //right pos
	int izq = v[i].second;
	int der = v[j].second;
	//Se va sumando de hacia el centro para que quede una particion equilibrada
	while(((izq + der) < maxFrecuency)){
		if (der <= izq){
			j--;
			der += v[j].second;
		}
		else{
			i++;
			izq += v[i].second;

		}
	}

	//Asigna "1"(true) a los elementos del lado izquierdo
	// y "0"(false) a los de la derecha
	for(int x = l; x < j; x++){
        if (code.find(v[x].first) == code.end()) {
            code[v[x].first] = vector<bool>(1, true);
        } else {
            code[v[x].first].push_back(true);
        }
	}
	for(int x = j; x <= r; x++){
		if (code.find(v[x].first) == code.end()) {
            code[v[x].first] = vector<bool>(1, false);
        } else {
            code[v[x].first].push_back(false);
        }
	}
	return j;
}

map<char, vector<bool>> bitsAssignment(vector<pair<char,int>> &vec){
    time_t start = clock();
    map<char, vector<bool>> code;
    shannonFano(vec, 0, int(vec.size())-1, code);
    time_t end = clock();
    cout << "Tiempo de asignacion de bits a cada simbolo: " << (double)(end - start) / CLOCKS_PER_SEC << " segundos." << endl;
    return code;
}

vector<pair<char, int>> sortSymbolsByFrecuency(map<char,int> &frecuency){
    time_t start = clock();
    vector<pair<char, int>> vec(frecuency.begin(), frecuency.end());
    sort(vec.begin(), vec.end(), sortByValue);
    time_t end = clock();
    cout << "Tiempo de ordenamiento de los simbolos: " << (double)(end - start) / CLOCKS_PER_SEC << " segundos." << endl;
    return vec;
}
