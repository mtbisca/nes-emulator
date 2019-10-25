import pygame
keys = [0] * 255
class CONTROL:
    def read_control(read_time):
        if read_time == 0:
            return keys[pygame.K_e]
            #return 1
        elif read_time == 1:
            return keys[pygame.K_r]
            #return 2
        elif read_time == 2:
            return keys[pygame.K_SPACE]
            #return 3
        elif read_time == 3:
            return keys[pygame.K_RETURN]
            #return 4
        elif read_time == 4:
            return keys[pygame.K_w]
            #return 5
        elif read_time == 5:
            return keys[pygame.K_s]
            #return 6
        elif read_time == 6:
            return keys[pygame.K_a]
            #return 7
        elif read_time == 7:
            return keys[pygame.K_d]
            #return 8
        else:
            return 0
