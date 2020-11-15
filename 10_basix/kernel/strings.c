/*
 * Сравнить 2 строки (Zero-Terminated)
 */
 
bool cmpstr(const char* a, const char* b) {
    
    while (*b) {
        
        if (*a != *b) {
            return false;
        }
        
        a++;
        b++;        
    }
    
    return true;
}
