/*
** Configuracoes iniciais
*/
void appinit(void);

/*
** Acoes quando um dos botoes vigiados mudarem de estado
*/
void button_changed (int pin, int v);

/*
** Acoes quando o tempo do timer acabar
*/
void timer_expired(void);
