#include "gd32vf103c_longan_nano.h"
#include <stdio.h>

void delay_1ms(uint32_t count)
{
    volatile uint64_t start_mtime, delta_mtime;

    volatile uint64_t tmp = get_timer_value();
    do {
    	start_mtime = get_timer_value();
    } while(start_mtime == tmp);


    uint64_t delay_ticks = SystemCoreClock / 4; // 1 second
    delay_ticks = delay_ticks * count / 1000;

    do {
    	delta_mtime = get_timer_value() - start_mtime;
    } while(delta_mtime < delay_ticks);

}

int main(void)
{
    gd_led_init(LED1);
    gd_led_init(LED2);
    gd_led_init(LED3);

    while(1){
        /* turn on led1, turn off led4 */
        gd_led_on(LED1);
        gd_led_off(LED3);
        delay_1ms(1000);
        /* turn on led2, turn off led1 */
        gd_led_on(LED2);
        gd_led_off(LED1);
        delay_1ms(1000);
        /* turn on led3, turn off led2 */
        gd_led_on(LED3);
        gd_led_off(LED2);
        delay_1ms(1000);
    }
}
