#include "event_driven.h"
#include "tarefa1.h"
#include "pindefs.h"

int pinos[3], estados[3], indice_disponivel;
void button_listen (int pin){
  if(indice_disponivel<3){
    pinos[indice_disponivel]=pin;
    estados[indice_disponivel]=1;
    indice_disponivel++;
  }
  else{
    Serial.println("Nao ha entradas disponiveis");
  }
}

void reset_listen(){
  int i;
  for(i=0; i<3; i++){
    pinos[i]=estados[i]=0;
  }
  indice_disponivel=0;
}

unsigned long tempo, tempo_inicial;
void timer_set (int ms){
  tempo = ms;
  tempo_inicial = millis();
}

void reset_timer(){
  tempo=tempo_inicial=0;  
}

void setup(){
  reset_timer();
  reset_listen();
  appinit();
}

void loop(){
  if(tempo && (millis()-tempo_inicial)>tempo){
    reset_timer();
    timer_expired();
  }
  
  if(indice_disponivel){
    int i;
    for(i=0; i<3; i++){
      int valor_lido = digitalRead(pinos[i]);
      if(valor_lido!=estados[i]){
        estados[i]=valor_lido;
        button_changed(pinos[i], estados[i]);
      }
    }
  }
}


