#include "event_driven.h"
#include "tarefa2.h"
#include "pindefs.h"

void appinit(){
  Serial.begin(9600);
  pinMode(KEY1, INPUT_PULLUP);
  pinMode(KEY2, INPUT_PULLUP);
  pinMode(KEY3, INPUT_PULLUP);
  pinMode(LED1, OUTPUT);
  pinMode(LED2, OUTPUT);
  pinMode(LED3, OUTPUT);
  pinMode(LED4, OUTPUT);
  digitalWrite(LED1, HIGH);
  digitalWrite(LED2, HIGH);
  digitalWrite(LED3, HIGH);
  digitalWrite(LED4, HIGH);
  button_listen(KEY1);
  button_listen(KEY2);
  timer_set(1000);
}

unsigned long tempo1 = 0, tempo2 = 1000;
int velocidade = 1000;
void button_changed(int pin, int v){
  Serial.print("O botao "); Serial.print(pin); Serial.print(" foi alterado para "); Serial.println(v);
  if(v=1){
    if(pin == KEY1){
      velocidade -= 100;
      tempo1=millis();
    }
    if(pin == KEY2){
      velocidade += 100;
      tempo2=millis();
    }
    Serial.println(tempo1);
    Serial.println(tempo2);
    if(abs(tempo1-tempo2)<500){
      Serial.print("Dois botoes diferentes foram apertados num intervalo menor que 500ms, ");
      Serial.print(abs(tempo1-tempo2));
      Serial.println("ms, portanto a aplicacao sera encerrada");
      while(1);
    }
  }
}

int ultimo_estado = HIGH;
void timer_expired(){
  if(ultimo_estado==HIGH){
    digitalWrite(LED4, LOW);
    ultimo_estado=LOW;
  }
  else{
    digitalWrite(LED4, HIGH);
    ultimo_estado=HIGH;
  }
  timer_set(velocidade);
}
