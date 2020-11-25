package com.mt.flt_chewie_player;

import java.io.File;

public class PlayStatus {
    private static PlayStatus infoInstance = null;
    private boolean canBackPressed=true;

    private PlayStatus() {
    }

    public static PlayStatus getInstance() {
        if (null == infoInstance) {
            synchronized (PlayStatus.class) {
                if (null == infoInstance) {
                    infoInstance = new PlayStatus();
                }
            }
        }
        return infoInstance;
    }

    public boolean isCanBackPressed() {
        return canBackPressed;
    }

    public void setCanBackPressed(boolean canBackPressed) {
        this.canBackPressed = canBackPressed;
    }
}
