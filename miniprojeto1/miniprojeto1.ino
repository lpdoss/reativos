#include "pindefs.h"

// Classes
class Relogio{
public:
  byte hora, minuto;

  Relogio(){
    hora = 0; 
    minuto = 0;
  }
  byte get_hora(){
    return hora;
  }
  void set_hora(byte hora){
    this->hora = hora;
  }
  byte get_minuto(){
    return minuto;
  }
  void set_minuto(byte minuto){
    this->minuto = minuto;
  }
  void incrementar_hora(){
    hora ++;
    if(hora == 24){
      hora = 0;
    }    
  }
  void incrementar_minuto(){
    minuto ++;
    if(minuto == 60){
      minuto = 0;
    }
  }
};

// Variaveis globais
Relogio relogio, alarme, temporario;
boolean relogio_config, alarme_config, alarme_ativo;
unsigned long debounce_delay = 800, debounce_last_time = 0;
/* Segment byte maps for numbers 0 to 9 */
const byte SEGMENT_MAP[] = {0xC0,0xF9,0xA4,0xB0,0x99,0x92,0x82,0xF8,0X80,0X90};
/* Byte maps to select digit 1 to 4 */
const byte SEGMENT_SELECT[] = {0xF1,0xF2,0xF4,0xF8};

// Funçoes auxiliares
void pciSetup(byte pin) {
  *digitalPinToPCMSK(pin) |= bit (digitalPinToPCMSKbit(pin));  // enable pin
  PCIFR  |= bit (digitalPinToPCICRbit(pin)); // clear any outstanding interrupt
  PCICR  |= bit (digitalPinToPCICRbit(pin)); // enable interrupt for the group
}

/* Write a decimal number between 0 and 9 to one of the 4 digits of the display */
void WriteNumberToSegment(byte Segment, byte Value){
  digitalWrite(LATCH_DIO,LOW);
  shiftOut(DATA_DIO, CLK_DIO, MSBFIRST, SEGMENT_MAP[Value]);
  shiftOut(DATA_DIO, CLK_DIO, MSBFIRST, SEGMENT_SELECT[Segment] );
  digitalWrite(LATCH_DIO,HIGH);
}

// Funcao responsavel por cancelar uma operaçao de alterar relogio ou alarme
void cancela(){
  relogio_config = alarme_config = false;
}


void setup() {
  Serial.begin(9600);
  pinMode(LED1, OUTPUT); pinMode(LED2, OUTPUT); pinMode(LED3, OUTPUT); pinMode(LED4, OUTPUT);
  digitalWrite(LED1,HIGH); digitalWrite(LED2,HIGH); digitalWrite(LED3,HIGH); digitalWrite(LED4,HIGH);
  pinMode(KEY1, INPUT_PULLUP); pinMode(KEY2, INPUT_PULLUP); pinMode(KEY3, INPUT_PULLUP);  
  pciSetup(KEY1); pciSetup(KEY2); pciSetup(KEY3);

  /* Set DIO pins to outputs */
  pinMode(LATCH_DIO,OUTPUT);
  pinMode(CLK_DIO,OUTPUT);
  pinMode(DATA_DIO,OUTPUT);
}

ISR (PCINT1_vect) { // handle pin change interrupt for A0 to A5 here
  Serial.println('BOTAO APERTADO');
  if((millis()-debounce_last_time)>debounce_delay){
    debounce_last_time = millis();
    if(digitalRead(KEY1)==0){
      Serial.println('KEY1');
      if(~relogio_config && ~alarme_config){
        Serial.println('RELOGIO CONFIG TRUE');
        relogio_config = true;
      }
      else if(relogio_config){
        Serial.println('RELOGIO INCREMENTAR HORA');
        relogio.incrementar_hora();
      }
      else if(alarme_config){
        Serial.println('ALARME INCREMENTAR HORA');
        alarme.incrementar_hora();
      }
    }
    else if(digitalRead(KEY2)==0){
      Serial.println('KEY2');
      if(~relogio_config && ~alarme_config){
        Serial.println('ALARME CONFIG TRUE');
        alarme_config = true;
      }
      else if(relogio_config){
        Serial.println('RELOGIO INCREMENTAR MINUTO');
        relogio.incrementar_minuto();
      }
      else if(alarme_config){
        Serial.println('ALARME INCREMENTAR MINUTO');
        alarme.incrementar_minuto();
      }
    }
    else if(digitalRead(KEY3)==0){
      Serial.println('KEY3');
      if(relogio_config || alarme_config){
        Serial.println('CANCELAR');
        relogio_config = alarme_config = false;
      }
    }
  }
}  

void loop() {
  /* Update the display with the current counter value */
  WriteNumberToSegment(0 , relogio.get_hora()/10);
  WriteNumberToSegment(1 , relogio.get_hora()%10);
  WriteNumberToSegment(2 , relogio.get_minuto()/10);
  WriteNumberToSegment(3 , relogio.get_minuto()%10);
}

