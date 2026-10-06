/*
 * Etape 1 (diagnostic) : appli bare-metal minimale qui ne fait QUE
 * initialiser le PS7 (ps7_init) et calibrer la DDR (ps7_post_config), puis
 * boucle indefiniment. Objectif : verifier si une calibration DDR faite
 * NATIVEMENT par le coeur ARM (et non pilotee registre par registre via
 * JTAG/XSCT) resout le probleme rencontre avec XSCT seul
 * ("AHB AP transaction error, DAP status 0xF0000021" a chaque ecriture DDR).
 *
 * Volontairement minuscule pour tenir entierement dans l'OCM (256 Ko) :
 * la DDR n'etant pas encore calibree au moment ou le debogueur charge
 * l'executable, le binaire lui-meme doit pouvoir etre charge et execute
 * sans toucher a la DDR (cf. instructions pour le script d'edition de liens
 * OCM-only).
 *
 * Une fois que cette appli tourne, retenter dans XSCT (meme JTAG, autre
 * session) :
 *   mrd 0x00100000 4
 *   dow -data {.../sample_in_rgb.bin} 0x00100000
 * Si ca passe cette fois, la DDR est calibree et on peut passer a l'etape 2
 * (l'appli complete qui embarque l'image et fait elle-meme le memcpy,
 * cf. main_step2_with_image.c).
 */

#include "ps7_init.h"
#include "xil_cache.h"

int main(void)
{
    ps7_init();
    ps7_post_config();

    /* Le DMA lit la DDR physique via S_AXI_HP0, qui n'est pas coherent avec
     * le cache du CPU. On desactive le cache D pour qu'aucune ligne sale ne
     * puisse plus tard ecraser l'image ecrite en DDR par JTAG. */
    Xil_DCacheDisable();

    while (1) {
    }

    return 0;
}
