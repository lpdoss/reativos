#include "pindefs.h"

// Classes
class Relogio {
  private:
    byte hora, minuto;

  public:
    Relogio() {
      hora = 0;
      minuto = 0;
    }
    byte get_hora() {
      return hora;
    }
    void set_hora(byte hora) {
      this->hora = hora;
    }
    byte get_minuto() {
      return minuto;
    }
    void set_minuto(byte minuto) {
      this->minuto = minuto;
    }
    void incrementar_hora() {
      hora ++;
      if (hora == 24) {
        hora = 0;
      }
    }
    void incrementar_minuto() {
      minuto ++;
      if (minuto == 60) {
        minuto = 0;
      }
    }
    void clonar(Relogio relogio) {
      hora = relogio.get_hora();
      minuto = relogio.get_minuto();
    }
    byte comparar(Relogio relogio) {
      if (hora == relogio.get_hora()) {
        if (minuto > relogio.get_minuto()) {
          return 1;
        }
        else if (minuto < relogio.get_minuto()) {
          return -1;
        }
      }
      else if (hora > relogio.get_hora()) {
        return 1;
      }
      else if (hora < relogio.get_hora()) {
        return -1;
      }
      return 0;
    }
    void avancar_relogio() {
      incrementar_minuto();
      if (get_minuto() == 0) {
        incrementar_hora();
      }
    }
};

// Variaveis globais
//// Volateis
volatile unsigned long salvar_estado;
volatile boolean relogio_config, alarme_config, alarme_ativo;

//// Não volateis
Relogio relogio, alarme, temporario;
unsigned long debounce_delay, debounce_last_time, intervalo_despertador, ultimo_incremento;
/* Segment byte maps for numbers 0 to 9 */
const byte SEGMENT_MAP[] = {0xC0, 0xF9, 0xA4, 0xB0, 0x99, 0x92, 0x82, 0xF8, 0X80, 0X90};
/* Byte maps to select digit 1 to 4 */
const byte SEGMENT_SELECT[] = {0xF1, 0xF2, 0xF4, 0xF8};
boolean despertando;

// Funçoes auxiliares
void pciSetup(byte pin) {
  *digitalPinToPCMSK(pin) |= bit (digitalPinToPCMSKbit(pin));  // enable pin
  PCIFR  |= bit (digitalPinToPCICRbit(pin)); // clear any outstanding interrupt
  PCICR  |= bit (digitalPinToPCICRbit(pin)); // enable interrupt for the group
}

/* Write a decimal number between 0 and 9 to one of the 4 digits of the display */
void WriteNumberToSegment(byte Segment, byte Value) {
  digitalWrite(LATCH_DIO, LOW);
  shiftOut(DATA_DIO, CLK_DIO, MSBFIRST, SEGMENT_MAP[Value]);
  shiftOut(DATA_DIO, CLK_DIO, MSBFIRST, SEGMENT_SELECT[Segment] );
  digitalWrite(LATCH_DIO, HIGH);
}

/*
   Reseta tudo que disrespeito a configuração do relogio e alarme.
*/
void resetar_configs() {
  relogio_config = alarme_config = false;
  salvar_estado = 0;
  digitalWrite(LED1, HIGH);
  digitalWrite(LED2, HIGH);
}

void setup() {
  Serial.begin(9600);
  pinMode(LED1, OUTPUT); pinMode(LED2, OUTPUT); pinMode(LED3, OUTPUT); pinMode(LED4, OUTPUT);
  digitalWrite(LED1, HIGH); digitalWrite(LED2, HIGH); digitalWrite(LED3, HIGH); digitalWrite(LED4, HIGH);
  pinMode(KEY1, INPUT_PULLUP); pinMode(KEY2, INPUT_PULLUP); pinMode(KEY3, INPUT_PULLUP);
  pinMode(BUZZ,OUTPUT); digitalWrite(BUZZ, HIGH);
  pciSetup(KEY1); pciSetup(KEY2); pciSetup(KEY3);

  /* Set DIO pins to outputs */
  pinMode(LATCH_DIO, OUTPUT);
  pinMode(CLK_DIO, OUTPUT);
  pinMode(DATA_DIO, OUTPUT);

  resetar_configs();
  alarme_ativo = false;
  debounce_last_time = 0;
  debounce_delay = 200;
  despertando = false;
}

ISR (PCINT1_vect) {
  if ((millis() - debounce_last_time) > debounce_delay) {
    debounce_last_time = millis();
    salvar_estado = millis();

    /*
       Caso o botão 1 seja apertado fora do estado de configuração, entrará no estado de configuração do relogio;
       Caso contrario, incrementará os minutos do que está sendo configurado no momento.
    */
    if (digitalRead(KEY1) == 0) {
      if (!relogio_config && !alarme_config) {
        temporario.clonar(relogio);
        relogio_config = true;
        digitalWrite(LED1, LOW);
      }
      else if (relogio_config) {
        temporario.incrementar_hora();
      }
      else if (alarme_config) {
        temporario.incrementar_hora();
      }
    }
    /*
       Caso o botão 2 seja apertado fora do estado de configuração, entrará no estado de configuração do alarme;
       Caso contrario, incrementará os minutos do que está sendo configurado no momento.
    */
    else if (digitalRead(KEY2) == 0) {
      if (!relogio_config && !alarme_config) {
        temporario.clonar(alarme);
        alarme_config = true;
        digitalWrite(LED2, LOW);
      }
      else if (relogio_config) {
        temporario.incrementar_minuto();
      }
      else if (alarme_config) {
        temporario.incrementar_minuto();
      }
    }
    /*
       Caso o botão 3 seja apertado no estado de configuração, todas as configurações serão descartadas;
       Caso contrario, ativará ou desativará o alarme, acendendo ou apagando o LED4, respectivamente.
    */
    else if (digitalRead(KEY3) == 0) {
      if (relogio_config || alarme_config) {
        resetar_configs();
        Serial.println("Configuracoes canceladas com sucesso!");
      }
      else {
        if (!alarme_ativo) {
          alarme_ativo = true;
          Serial.println("Alarme ativado com sucesso!");
          digitalWrite(LED4, LOW);
        }
        else {
          alarme_ativo = false;
          Serial.println("Alarme desativado com sucesso!");
          digitalWrite(LED4, HIGH);
        }
      }
    }
  }
}

/*
   Exibe no display as horas/minutos do relogio passado por parametro.
*/
void exibir(Relogio r) {
  WriteNumberToSegment(0 , r.get_hora() / 10);
  WriteNumberToSegment(1 , r.get_hora() % 10);
  WriteNumberToSegment(2 , r.get_minuto() / 10);
  WriteNumberToSegment(3 , r.get_minuto() % 10);
}

/*
   Verifica o relogio se esta coincidente com o alarme e, caso afirmativo, emite-se um efeito sonoro.
*/
void verificar_alarme() {
  if (alarme_ativo && relogio.comparar(alarme) == 0) {
    if (!despertando) {
      intervalo_despertador = millis();
      despertando = true;
    }
    else if ((millis() - intervalo_despertador) < 100) {
      //Serial.print("vvv");
      digitalWrite(BUZZ, LOW);
    }
    else if ((millis() - intervalo_despertador) < 200) {
      //Serial.print("...");
      digitalWrite(BUZZ, HIGH);
    }
    else {
      intervalo_despertador = millis();
    }
  }
  else {
    digitalWrite(BUZZ, HIGH);
    despertando = false;
  }
}

/*
   Avança o relogio
*/
void avancar_relogio() {
  if ((millis() - ultimo_incremento) > 60000) {
    ultimo_incremento = millis();
    relogio.avancar_relogio();
  }
}

/*
   Transiciona os possiveis estados do visor, configuração do relogio e do alarme, avança o relogio e verifica o alarme;
   Caso nennhum botão seja apertado num periodo de 2 segundos, o estado temporario é consolidado, as variaveis resetadas e o respectivo LED apagado.
*/
void loop() {
  if (relogio_config) {
    if ((millis() - salvar_estado) > 2000) {
      relogio.set_hora(temporario.get_hora());
      relogio.set_minuto(temporario.get_minuto());
      resetar_configs();
      ultimo_incremento = millis(); // Começa a rolar o tempo a partir do salvamento do novo estado do relogio
      Serial.println("Configuracoes do relogio salvas com sucesso!");
      digitalWrite(BUZZ, LOW);
      delay(100);
      digitalWrite(BUZZ, HIGH);
      digitalWrite(LED1, HIGH);
    }
    else {
      exibir(temporario);
    }
  }
  else if (alarme_config) {
    if ((millis() - salvar_estado) > 2000) {
      alarme.set_hora(temporario.get_hora());
      alarme.set_minuto(temporario.get_minuto());
      resetar_configs();
      Serial.println("Configuracoes do alarme salvas com sucesso!");
      digitalWrite(BUZZ, LOW);
      delay(100);
      digitalWrite(BUZZ, HIGH);
      digitalWrite(LED2, HIGH);
    }
    else {
      exibir(temporario);
    }
  }
  else {
    avancar_relogio();
    verificar_alarme();
    exibir(relogio);
  }
}

