#import "gdyz.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <openssl/sha.h>
#include <openssl/rc4.h>
#import "curl.h"
#include <time.h>
#import "cJSON.h"
#include <sys/mount.h>
#include <openssl/aes.h>
#include <openssl/evp.h>
#import "fishhook.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>


//公告接口
#define GGhost "http://dfm.rivp.cn/code_api.php"
//公告密钥 勿动
#define GGKEYS @"E7cZLp0mUwFtKXDR"
//接口地址
#define host "http://dfm.rivp.cn/api.php"
//RC4密钥
#define KEYS "H1MHOX4YuzNgqQoJ"
//签名密钥
#define SECRET_KEY "GGdW987dfgD8gDF8d"
//软件代号
#define appid "123890"
//软件版本号
#define appv "1.0.1"
//激活码长度
#define kml 14
//狗蛋算法key
#define NEWALG_KEY "N7pQ4vZ1yBf3L0TmC2R8X9aE5wJ6hK3D"
//狗蛋算法iv
#define NEWALG_IV  "A1B2C3D4E5F6G7H8"

BOOL sub_m889283YhOXNKlS0tZExbRameuKLu09M0FzgpOosYk3HJw0c1b0dpt = NO;

static const unsigned char sub_82100_sbox[256] = {
0xA7,0x3D,0x91,0xE2,0x5C,0x0B,0xF8,0x46,0x7A,0x12,0xB3,0xD5,0x29,0x6E,0x84,0xC1,
0x4F,0x9B,0x23,0x8D,0x50,0x37,0xFE,0x02,0x6A,0xCE,0x18,0x75,0xA1,0x5E,0x97,0x0D,
0x33,0xEC,0x41,0x89,0x14,0xB7,0xDA,0x68,0xFD,0x27,0xC9,0x71,0x0F,0x56,0xAB,0x35,
0xD3,0x22,0x80,0xF1,0x4A,0x9D,0x60,0x16,0xBE,0x2C,0x73,0x08,0xE9,0x45,0xAF,0x31,
0x9F,0x58,0x06,0xA5,0xCB,0x10,0x7E,0x2A,0x94,0xDD,0x39,0x63,0xC6,0x1B,0x72,0x04,
0xE4,0x53,0x98,0x20,0x8A,0xF6,0x47,0x0E,0xBD,0x3A,0x69,0x15,0xDC,0x51,0x87,0x2F,
0x76,0x05,0xE7,0x42,0xB0,0x1F,0x64,0xCA,0x09,0x8F,0xF2,0x54,0x36,0xA8,0x23,0x93,
0x6F,0x0A,0xC0,0x5B,0x19,0xED,0x48,0x82,0xD7,0x34,0x70,0x1A,0xB9,0x26,0xCF,0x03,
0x8E,0xF3,0x57,0x2D,0xA0,0x11,0xC7,0x65,0x0C,0xEA,0x49,0x77,0x28,0xB5,0x1E,0x92,
0x62,0x07,0xAC,0x3F,0xD1,0x24,0x86,0xFB,0x40,0x9A,0x13,0xE6,0x5A,0x2B,0xC4,0x75,
0x0A,0xB8,0x21,0x98,0xDD,0x32,0x6C,0xF4,0x53,0x01,0xA9,0x7B,0x16,0xE3,0x4D,0x90,
0x2E,0xC2,0x68,0x15,0xBF,0x44,0x79,0x06,0xEB,0x50,0x95,0x1C,0xA4,0x3E,0xD6,0x27,
0x81,0xF0,0x5D,0x0B,0xC5,0x22,0x6D,0xA2,0x38,0x9C,0x17,0xE8,0x4E,0x71,0x03,0xB1,
0x5F,0x25,0xCE,0x08,0x93,0xF7,0x4B,0x10,0xA6,0x3C,0x69,0x1D,0xC8,0x52,0x80,0x2A,
0x74,0x05,0xE0,0x41,0xB2,0x19,0x66,0xCD,0x0F,0x8C,0xF5,0x57,0x35,0xAE,0x23,0x96,
0x61,0x09,0xC1,0x5C,0x12,0xEF,0x48,0x83,0xD9,0x30,0x78,0x1B,0xBA,0x26,0xC3,0x04
};

static const unsigned char sub_82100_perm16[16] = {7,0,14,2,13,4,11,6,15,1,12,3,10,5,8,9};
static const unsigned char sub_82100_iperm16[16] = {1,9,3,11,5,13,7,0,14,15,12,6,10,4,2,8};
static const unsigned char sub_82100_w0[16] = {0x21,0x43,0x65,0x87,0xA9,0xCB,0xED,0x0F,0x10,0x32,0x54,0x76,0x98,0xBA,0xDC,0xFE};
static const unsigned char sub_82100_w1[16] = {0xFE,0xDC,0xBA,0x98,0x76,0x54,0x32,0x10,0x0F,0xED,0xCB,0xA9,0x87,0x65,0x43,0x21};

@implementation gdyz

static void fuckkkk() {
    __asm__ volatile(
        "mov x0, #0\n"
        "str x0, [x0]\n"
        ".long 0xE7F000F0\n"
     );
    __builtin_trap();
}

static void sub_69247(){
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        BOOL isAlertControllerPresented = NO;
        UIViewController *viewController = [UIApplication sharedApplication].keyWindow.rootViewController;
        while (viewController.presentedViewController) {
            if ([viewController.presentedViewController isKindOfClass:[UIAlertController class]]) {
                isAlertControllerPresented = YES;
                break;
            }
            viewController = viewController.presentedViewController;
        }
        if (!isAlertControllerPresented) {
            UIAlertController *xqxx = [UIAlertController alertControllerWithTitle:@"Superman" message:@"请输入激活码" preferredStyle:UIAlertControllerStyleAlert];
            [xqxx addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                textField.placeholder = @"激活码";
                textField.clearButtonMode = UITextFieldViewModeAlways;
            }];
            [xqxx addAction:[UIAlertAction actionWithTitle:@"激活" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSArray * textfields = xqxx.textFields;
                UITextField * namefield = textfields[0];
                NSString *cc=namefield.text;
                if(cc.length != kml){
                    sub_99748("激活码不存在");
                    return;
                }
                sub_19745([cc UTF8String]);
            }]];
            [viewController presentViewController:xqxx animated:YES completion:nil];
        }
        
    });
}

static void sub_99748(const char * a1){
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"验证失败" message:[NSString stringWithUTF8String:a1] preferredStyle:UIAlertControllerStyleAlert];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [alertController dismissViewControllerAnimated:YES completion:nil];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults removeObjectForKey:@"EH3Z9PQL7B"];
            [defaults synchronize];
            sub_69247();
        });
        
    });
}

static void sub_31748(const char * a1){
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"验证成功" message:[NSString stringWithFormat:@"到期时间:%@",[NSString stringWithUTF8String:a1]] preferredStyle:UIAlertControllerStyleAlert];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [alertController dismissViewControllerAnimated:YES completion:nil];
        });
    });
}

size_t sub_17459(void *contents, size_t size, size_t nmemb, void *userp) {
    size_t total_size = size * nmemb;
    char* response = (char*)contents;
    char** response_data = (char**)userp;
    *response_data = (char*)realloc(*response_data, total_size + 1);
    strncpy(*response_data, response, total_size);
    (*response_data)[total_size] = '\0';
    return total_size;
}

static void sub_61474(const char *a1, unsigned char *a2) {
    SHA256_CTX a3;
    SHA256_Init(&a3);
    SHA256_Update(&a3, a1, strlen(a1));
    SHA256_Final(a2, &a3);
}
static const char * sub_54741(const char *a1) {
    unsigned char a2[SHA256_DIGEST_LENGTH];
    sub_61474(a1, a2);
    static char hex[SHA256_DIGEST_LENGTH * 2 + 1];
    for (int i = 0; i < SHA256_DIGEST_LENGTH; i++) {
        sprintf(&hex[i*2], "%02x", a2[i]);
    }
    return hex;
}



static void sub_32417(char *data, unsigned long data_len, char *key, unsigned long key_len) {
    unsigned char s[256];
    unsigned char k[256];
    unsigned char t;
    int i, j, x;
    for (i = 0; i < 256; i++) {
        s[i] = i;
        k[i] = key[i % key_len];
    }
    j = 0;
    for (i = 0; i < 256; i++) {
        j = (j + s[i] + k[i]) % 256;
        t = s[i];
        s[i] = s[j];
        s[j] = t;
    }
    i = 0;
    j = 0;
    for (x = 0; x < data_len; x++) {
        i = (i + 1) % 256;
        j = (j + s[i]) % 256;
        t = s[i];
        s[i] = s[j];
        s[j] = t;
        data[x] ^= s[(s[i] + s[j]) % 256];
        data[data_len] = '\0';
    }
}

static void sub_55691(char* data, unsigned long data_len, char* key, unsigned long key_len) {
    sub_32417(data, data_len, key, key_len);
}

static void sub_15472(char* data, unsigned long data_len, char* key, unsigned long key_len) {
    sub_32417(data, data_len, key, key_len);
}

static void sub_82100_rk(unsigned char rk[24][8]){
    const char *k = NEWALG_KEY;
    unsigned int s = 0;
    for(int i=0;i<strlen(k);i++){ s = (s + (unsigned int)k[i]) ^ (s<<5) ^ (s>>3); }
    for(int r=0;r<24;r++){
        for(int j=0;j<8;j++){
            s ^= (s<<7);
            s ^= (s>>9);
            s ^= 0x9E3779B9u;
            rk[r][j] = (unsigned char)(s & 0xFF);
        }
    }
}

static void sub_82100_f(const unsigned char *R, const unsigned char *rk, unsigned char *out, int round){
    static const unsigned char cst[8] = {0x5D,0xA3,0x17,0xC9,0x2B,0x6E,0x81,0xF4};
    unsigned char t[8], u[8], y[8];
    for(int i=0;i<8;i++){ t[i] = (unsigned char)(R[i] ^ rk[i]); }
    for(int i=0;i<8;i++){ u[i] = sub_82100_sbox[t[i]]; }
    for(int i=0;i<8;i++){
        unsigned char a = u[i];
        unsigned char b = u[(i+1)&7];
        unsigned char rot1 = (unsigned char)((b<<1) | (b>>7));
        unsigned char mix = (unsigned char)((a + rot1 + cst[(round+i)&7]) & 0xFF);
        unsigned char rot3 = (unsigned char)((mix<<3) | (mix>>5));
        unsigned char rot5 = (unsigned char)((u[(i+2)&7]<<5) | (u[(i+2)&7]>>3));
        y[i] = (unsigned char)((mix ^ rot3 ^ rot5 ^ 0xA5) & 0xFF);
    }
    for(int i=0;i<8;i++){ out[i] = y[i]; }
}

static void sub_82100_be(const unsigned char *in, unsigned char *out){
    unsigned char blk[16];
    for(int i=0;i<16;i++){ blk[i] = in[i] ^ sub_82100_w0[i]; }
    unsigned char pblk[16];
    for(int i=0;i<16;i++){ pblk[i] = blk[sub_82100_perm16[i]]; }
    unsigned char L[8], R[8], F[8];
    memcpy(L, pblk, 8); memcpy(R, pblk+8, 8);
    unsigned char rk[24][8];
    sub_82100_rk(rk);
    for(int r=0;r<24;r++){
        sub_82100_f(R, rk[r], F, r);
        unsigned char nR[8];
        for(int i=0;i<8;i++){ nR[i] = (unsigned char)(L[i] ^ F[i]); }
        memcpy(L, R, 8);
        memcpy(R, nR, 8);
    }
    unsigned char outblk[16];
    memcpy(outblk, R, 8);
    memcpy(outblk+8, L, 8);
    unsigned char ipblk[16];
    for(int i=0;i<16;i++){ ipblk[i] = outblk[sub_82100_iperm16[i]]; }
    for(int i=0;i<16;i++){ out[i] = (unsigned char)(ipblk[i] ^ sub_82100_w1[i]); }
}

static void sub_82100_bd(const unsigned char *in, unsigned char *out){
    unsigned char blk[16];
    for(int i=0;i<16;i++){ blk[i] = (unsigned char)(in[i] ^ sub_82100_w1[i]); }
    unsigned char pblk[16];
    for(int i=0;i<16;i++){ pblk[i] = blk[sub_82100_perm16[i]]; }
    unsigned char L[8], R[8], F[8];
    memcpy(R, pblk, 8); memcpy(L, pblk+8, 8);
    unsigned char rk[24][8];
    sub_82100_rk(rk);
    for(int r=23;r>=0;r--){
        sub_82100_f(L, rk[r], F, r);
        unsigned char nL[8];
        for(int i=0;i<8;i++){ nL[i] = (unsigned char)(R[i] ^ F[i]); }
        memcpy(R, L, 8);
        memcpy(L, nL, 8);
    }
    unsigned char outblk[16];
    memcpy(outblk, L, 8);
    memcpy(outblk+8, R, 8);
    unsigned char ipblk[16];
    for(int i=0;i<16;i++){ ipblk[i] = outblk[sub_82100_iperm16[i]]; }
    for(int i=0;i<16;i++){ out[i] = (unsigned char)(ipblk[i] ^ sub_82100_w0[i]); }
}

static char* sub_82100_enc(const unsigned char *in, size_t len, size_t *out_len){
    size_t bs = 16;
    size_t pad = bs - (len % bs);
    size_t nlen = len + pad;
    unsigned char *buf = (unsigned char*)malloc(nlen);
    for(size_t i=0;i<len;i++) buf[i] = in[i];
    for(size_t i=len;i<nlen;i++) buf[i] = (unsigned char)pad;
    unsigned char iv[16];
    memcpy(iv, NEWALG_IV, 16);
    unsigned char *out = (unsigned char*)malloc(nlen);
    unsigned char prev[16];
    memcpy(prev, iv, 16);
    for(size_t off=0; off<nlen; off+=bs){
        unsigned char blk[16];
        for(int i=0;i<16;i++) blk[i] = (unsigned char)(buf[off+i] ^ prev[i]);
        unsigned char enc[16];
        sub_82100_be(blk, enc);
        memcpy(out+off, enc, 16);
        memcpy(prev, enc, 16);
    }
    free(buf);
    *out_len = nlen;
    char *ret = (char*)malloc(nlen);
    memcpy(ret, out, nlen);
    free(out);
    return ret;
}

static char* sub_82100_dec(const unsigned char *in, size_t len, size_t *out_len){
    size_t bs = 16;
    if(len==0 || (len%bs)!=0) return NULL;
    unsigned char iv[16];
    memcpy(iv, NEWALG_IV, 16);
    unsigned char *out = (unsigned char*)malloc(len);
    unsigned char prev[16];
    memcpy(prev, iv, 16);
    for(size_t off=0; off<len; off+=bs){
        unsigned char dec[16];
        sub_82100_bd(in+off, dec);
        for(int i=0;i<16;i++) out[off+i] = (unsigned char)(dec[i] ^ prev[i]);
        memcpy(prev, in+off, 16);
    }
    unsigned char pad = out[len-1];
    size_t nlen = (pad>0 && pad<=16) ? (len - pad) : len;
    char *ret = (char*)malloc(nlen+1);
    memcpy(ret, out, nlen);
    ret[nlen] = '\0';
    free(out);
    *out_len = nlen;
    return ret;
}

static const char* sub_67417() {
    time_t t;
    struct tm *tm_info;
    static _Thread_local char buffer[80];
    time(&t);
    tm_info = localtime(&t);
    strftime(buffer, sizeof(buffer), "%Y-%m-%d %H:%M", tm_info);
    return buffer;
}

static const char* sub_59746(const char* name, ...) {
    cJSON *root = cJSON_CreateObject();
    va_list args;
    va_start(args, name);
    const char* key = name;
    const char* value;
    while (key != NULL) {
        value = va_arg(args, const char*);
        if (value == NULL) {
            break;
        }
        cJSON_AddItemToObject(root, key, cJSON_CreateString(value));
        key = va_arg(args, const char*);
    }
    va_end(args);
    char *json_string = cJSON_Print(root);
    cJSON_Delete(root);
    return sub_98124(json_string);
}

static const char* sub_98124(const char* json_string) {
    cJSON *json = cJSON_Parse(json_string);
    char *minified_json_string = cJSON_PrintUnformatted(json);
    cJSON_Delete(json);
    return minified_json_string;
}

static const char* sub_24176(const char *a1) {
    unsigned long data_len = strlen(a1);
    unsigned long key_len = strlen(KEYS);
    char *data_dynamic = (char *) malloc((data_len + 1) * sizeof(char));
    char *key_dynamic = (char *) malloc((key_len + 1) * sizeof(char));
    strcpy(data_dynamic, a1);
    strcpy(key_dynamic, KEYS);
    sub_55691(data_dynamic, data_len, key_dynamic, key_len);
    size_t elen = 0;
    char *enc = sub_82100_enc((unsigned char*)data_dynamic, data_len, &elen);
    char *hex = (char *) malloc(elen * 2 + 1);
    for (size_t i = 0; i < elen; i++) {
        sprintf(hex + (i * 2), "%02x", (unsigned char)enc[i]);
    }
    hex[elen*2] = '\0';
    return sub_33584(hex);
}

static const char* sub_94715(const char *a1) {
    const char * a11=sub_33584(a1);
    unsigned long key_len = strlen(KEYS);
    char *key_dynamic = (char *) malloc((key_len + 1) * sizeof(char));
    strcpy(key_dynamic, KEYS);
    unsigned long ciphertext_len = strlen(a11) / 2;
    unsigned char *ciphertext = (unsigned char *) malloc(ciphertext_len * sizeof(unsigned char));
    for (unsigned long i = 0; i < ciphertext_len; i++) {
        sscanf(a11 + (i * 2), "%2hhx", &ciphertext[i]);
    }
    size_t dlen = 0;
    char *dec = sub_82100_dec(ciphertext, ciphertext_len, &dlen);
    if(dec==NULL){ return NULL; }
    sub_15472((char *)dec, dlen, key_dynamic, key_len);
    return (const char *)dec;
}

static const char * sub_ts() {
    static _Thread_local char buf[32];
    long t = time(NULL);
    sprintf(buf, "%ld", t);
    return buf;
}

static const char * sub_nonce() {
    static _Thread_local char buf[32];
    int r = arc4random_uniform(899999) + 100000; // 6位随机数
    sprintf(buf, "%d", r);
    return buf;
}

static const char * sub_sign(const char *code,const char *uuid,const char *ts,const char *nonce) {
    static _Thread_local char outbuf[256];
    char mix[256];
    snprintf(mix, sizeof(mix), "%s%s%s%s%s", code, uuid, ts, nonce, SECRET_KEY);

    unsigned char hash[SHA256_DIGEST_LENGTH];
    SHA256_CTX ctx;
    SHA256_Init(&ctx);
    SHA256_Update(&ctx, mix, strlen(mix));
    SHA256_Final(hash, &ctx);

    for (int i = 0; i < SHA256_DIGEST_LENGTH; i++) {
        sprintf(outbuf + i * 2, "%02x", hash[i]);
    }
    return outbuf;
}

//请求
static void sub_19745(const char * a1){
    const char *a11 = strdup(a1);
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        const char *txt = sub_59746("code",a11,"uuid",sub_62475(),"appid",appid,"appv",appv,NULL);
        const char * txt1 = sub_24176(txt);//加
        CURL *curl = curl_easy_init();
        curl_global_init(CURL_GLOBAL_ALL);
        curl_easy_setopt(curl, CURLOPT_URL, host);
        curl_easy_setopt(curl, CURLOPT_POST, 1);
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, txt1);
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, sub_17459);
        char* response_data = NULL;
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response_data);
        CURLcode res = curl_easy_perform(curl);
        if (res != CURLE_OK) {
            kill(getpid(), SIGKILL);
            fuckkkk();
        }
        if (!response_data){
            kill(getpid(), SIGKILL);
            fuckkkk();
        }
        
        const char * js = sub_94715(response_data);//加
        cJSON *json = cJSON_Parse(js);
        cJSON *json1 = cJSON_GetObjectItem(json, "data");
        const char *date = json1->valuestring;//状态码
        
        cJSON *json2 = cJSON_GetObjectItem(json, "state");
        const char *status = json2->valuestring;//状态
        
        cJSON *json3 = cJSON_GetObjectItem(json, "code");
        const char *code = json3->valuestring;//激活码
        
        cJSON *json4 = cJSON_GetObjectItem(json, "uuid");
        const char *uuid = json4->valuestring;//机器码
        
        cJSON *json5 = cJSON_GetObjectItem(json, "time");
        const char *time1 = json5->valuestring;//到期时间
        
        cJSON *json6 = cJSON_GetObjectItem(json, "sgin");
        const char *sgin = json6->valuestring;//签名
      
        cJSON *jsonTs    = cJSON_GetObjectItem(json, "ts");
        cJSON *jsonNonce = cJSON_GetObjectItem(json, "nonce");
        cJSON *jsonSign  = cJSON_GetObjectItem(json, "sign");
        if (!jsonTs || !jsonNonce || !jsonSign ||
            !jsonTs->valuestring ||
            !jsonNonce->valuestring ||
            !jsonSign->valuestring) {
            sub_99748("验证失败");
            return;
        }
        const char *respTs    = jsonTs->valuestring;
        const char *respNonce = jsonNonce->valuestring;
        const char *respSign  = jsonSign->valuestring;
        long long nowTs = (long long)time(NULL);
        long long srvTs = atoll(respTs);
        if (llabs(nowTs - srvTs) > 5) {
            sub_99748("验证失败");
            return;
        }
        const char *calcSign = sub_sign(code, uuid, respTs, respNonce);
        if (strcmp(calcSign, respSign) != 0) {
            sub_99748("验证失败");
            return;
        }
        const char *sgin1 =sub_54741(sub_67417());//签名
        if (strcmp(date, "Q3LZ9TDF8R") != 0) {
            sub_99748(status);
            return;
        }else if (strcmp(status, "W7KP4J9HM2") != 0) {
            sub_99748("激活码不存在");
            return;
        }else if (strcmp(code, a11) != 0) {
            sub_99748("激活码不存在");
            return;
        }else if (strcmp(uuid, sub_62475()) != 0) {
            sub_99748("激活码不存在");
            return;
        }else if (strcmp(sgin, sgin1) != 0) {
            sub_99748("激活码不存在");
            return;
        }else{
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:[NSString stringWithUTF8String:a11] forKey:@"EH3Z9PQL7B"];
            [defaults synchronize];
            sub_31748(time1);
           
            sub_m889283YhOXNKlS0tZExbRameuKLu09M0FzgpOosYk3HJw0c1b0dpt = YES;
          
        }
    });
}

//获取特征码
static const char *sub_99999(const char *uuidRaw) {
    @autoreleasepool {
        NSString *uuid = [NSString stringWithUTF8String:(uuidRaw ?: "")];
        NSString *ios = [[UIDevice currentDevice] systemVersion];
        NSString *model = [[UIDevice currentDevice] model];
        NSString *combo = [NSString stringWithFormat:@"%@%@%@", uuid, ios, model];
        static char final_result[256] = {0};
        strncpy(final_result, [combo UTF8String], sizeof(final_result) - 1);
        return final_result;
    }
}
static const char *sub_62475() {
    struct statfs buf;
    statfs("/", &buf);
    char* prefix = "com.apple.os.update-";
    if(strstr(buf.f_mntfromname, prefix)) {
        NSString *ocString1 = [[NSString alloc] initWithUTF8String:buf.f_mntfromname + strlen(prefix)];
        NSString *stringOne = [ocString1 substringToIndex:36];
        NSMutableString *ocString2 = [NSMutableString stringWithString:stringOne];
        [ocString2 replaceCharactersInRange:NSMakeRange(8, 1) withString:@"-"];
        [ocString2 replaceCharactersInRange:NSMakeRange(13, 1) withString:@"-"];
        [ocString2 replaceCharactersInRange:NSMakeRange(18, 1) withString:@"-"];
        [ocString2 replaceCharactersInRange:NSMakeRange(23, 1) withString:@"-"];
        const char *cString = [ocString2 UTF8String];
        return sub_99999(cString);
    } else {
        return sub_25497();
    }
}
static const char *sub_25497(void) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSData *data = [fileManager contentsAtPath:@"/var/mobile/Library/Logs/AppleSupport/general.log"];
    if (!data) return sub_99999("0000000000-00000-00000-0000000000000");

    NSMutableString *string = [[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString *regex = @"serial\":\"(.*?)\"";
    NSError *error = nil;
    NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:regex options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray *result = [re matchesInString:string options:0 range:NSMakeRange(0, string.length)];
    for (NSTextCheckingResult *match in result) {
        NSString *serial = [string substringWithRange:[match rangeAtIndex:1]];
        return sub_99999([serial UTF8String]);
    }

    return sub_99999("0000000000-00000-00000-0000000000000");
}
static const char* sub_33584(const char *str) {
    int len = (int)strlen(str);
    char *result = (char*)malloc((len + 1) * sizeof(char));
    strcpy(result, str);
    for (int i = 0; i < len - 1; i += 2) {
        char temp = result[i];
        result[i] = result[i + 1];
        result[i + 1] = temp;
    }
    return result;
}
static int fake_printf(const char * __restrict format, ...) {
    return 0;
}

static void fake_NSLog(NSString *format, ...) {
    
}

static void __attribute__((constructor)) sub_49047() {
    rebind_symbols((struct rebinding[]){
        {"printf", (void *)fake_printf, NULL},
        {"NSLog",  (void *)fake_NSLog, NULL},
    }, 2);
    
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *code = [defaults objectForKey:@"EH3Z9PQL7B"];
        if (!code) {
            sub_69247();
        }else{
            sub_19745([code UTF8String]);
        }
}

//==========================================控包=================================================
static void sub_78438(unsigned char *key, int key_len, unsigned char *data, int data_len) {
    unsigned char s[256];
    for (int i = 0; i < 256; i++) s[i] = i;
    int j = 0;
    for (int i = 0; i < 256; i++) {
        j = (j + s[i] + key[i % key_len]) & 0xFF;
        unsigned char tmp = s[i]; s[i] = s[j]; s[j] = tmp;
    }
    int i = 0; j = 0;
    for (int n = 0; n < data_len; n++) {
        i = (i + 1) & 0xFF;
        j = (j + s[i]) & 0xFF;
        unsigned char tmp = s[i]; s[i] = s[j]; s[j] = tmp;
        data[n] ^= s[(s[i] + s[j]) & 0xFF];
    }
}

static NSString *sub_78439(NSString *input) {
    const char *str = [input UTF8String];
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(str, (CC_LONG)strlen(str), hash);
    NSMutableString *out = [NSMutableString stringWithCapacity:64];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++)
        [out appendFormat:@"%02x", hash[i]];
    return out;
}

static NSString *sub_78440() {
    return [NSString stringWithFormat:@"%ld", time(NULL)];
}

static NSString *sub_78441() {
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

static NSString *sub_78442(NSData *data) {
    return [data base64EncodedStringWithOptions:0];
}

static NSData *sub_78443(NSString *str) {
    return [[NSData alloc] initWithBase64EncodedString:str options:0];
}

size_t sub_78447(void *contents, size_t size, size_t nmemb, void *userp) {
    size_t total = size * nmemb;
    NSMutableData *data = (__bridge NSMutableData *)userp;
    [data appendBytes:contents length:total];
    return total;
}

static void sub_78444() {
    NSString *time = sub_78440();
    NSString *uuid = sub_78441();
    NSString *key = GGKEYS;
    NSString *sign = sub_78439([NSString stringWithFormat:@"%@%@%@", uuid, time, key]);

    NSDictionary *dict = @{@"uuid": uuid, @"time": time, @"sign": sign};
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];

    unsigned char *buf = (unsigned char *)malloc(jsonData.length);
    memcpy(buf, jsonData.bytes, jsonData.length);
    sub_78438((unsigned char *)[key UTF8String], (int)key.length, buf, (int)jsonData.length);
    NSData *encData = [NSData dataWithBytesNoCopy:buf length:jsonData.length freeWhenDone:YES];
    NSString *body = sub_78442(encData);

    CURL *curl = curl_easy_init();
    if (!curl) return;

    NSMutableData *responseData = [NSMutableData data];
    curl_global_init(CURL_GLOBAL_ALL);
    curl_easy_setopt(curl, CURLOPT_URL, GGhost);
    curl_easy_setopt(curl, CURLOPT_POST, 1L);
    curl_easy_setopt(curl, CURLOPT_POSTFIELDS, [body UTF8String]);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, sub_78447);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, (__bridge void *)responseData);
    struct curl_slist *headers = NULL;
    headers = curl_slist_append(headers, "Content-Type: application/octet-stream");
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
    CURLcode res = curl_easy_perform(curl);
    curl_easy_cleanup(curl);
    curl_slist_free_all(headers);
    curl_global_cleanup();

    if (res != CURLE_OK || responseData.length == 0) {
        exit(1337);
        kill(getpid(), SIGKILL);
        fuckkkk();
    }

    NSString *respStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    NSData *decData = sub_78443(respStr);
    if (!decData) {
        exit(1337);
        kill(getpid(), SIGKILL);
        fuckkkk();
    }

    unsigned char *buf2 = (unsigned char *)malloc(decData.length);
    memcpy(buf2, decData.bytes, decData.length);
    sub_78438((unsigned char *)[key UTF8String], (int)key.length, buf2, (int)decData.length);
    NSData *json = [NSData dataWithBytesNoCopy:buf2 length:decData.length freeWhenDone:YES];

    NSError *err = nil;
    NSDictionary *respDict = [NSJSONSerialization JSONObjectWithData:json options:0 error:&err];
    if (err || ![respDict isKindOfClass:[NSDictionary class]]) {
        exit(1337);
        kill(getpid(), SIGKILL);
        fuckkkk();
    }

    NSString *status = respDict[@"$2y$10$Y4EdQAw6tiAYf/8YdSnVYOzM7qOZXO3AW2HEOaVY6ldqHAvzZ3iSS1.44"];
    if (![status isKindOfClass:[NSString class]] || ![status isEqualToString:@"$2y$10$skBuhTzJe67Pi4DJxHiruec8Zhr68P/fWDc3BLrRMf7iGRHSwG5oK1.44"]) {
        exit(1337);
        kill(getpid(), SIGKILL);
        fuckkkk();
    }

    NSString *notice = respDict[@"notice"];
    if ([notice isKindOfClass:[NSString class]] && notice.length > 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            static UIWindow *noticeWindow = nil;
            if (noticeWindow) return;

            noticeWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            noticeWindow.windowLevel = UIWindowLevelAlert + 1;
            noticeWindow.backgroundColor = [UIColor clearColor];
            noticeWindow.rootViewController = [UIViewController new];
            [noticeWindow makeKeyAndVisible];

            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"📢 公告"
                                                                           message:notice
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"我知道了"
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * _Nonnull action) {
                noticeWindow.hidden = YES;
                noticeWindow = nil;
            }]];

            [noticeWindow.rootViewController presentViewController:alert animated:YES completion:nil];
        });
    }
}
static void sub_78445() {
    sub_78444();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        while (1) {
            sleep(30);
            sub_78444();
        }
    });
}
__attribute__((constructor))
static void sub_78446() {
    sub_78445();
}

@end
