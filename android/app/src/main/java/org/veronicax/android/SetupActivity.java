package org.veronicax.android;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.provider.DocumentsContract;
import android.provider.Settings;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;
import java.io.File;

public final class SetupActivity extends Activity {
    private static final int PICK_TREE = 41;
    private TextView status;

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        int pad = (int)(24 * getResources().getDisplayMetrics().density);
        root.setPadding(pad, pad, pad, pad);
        TextView title = new TextView(this);
        title.setText("Project Veronica X — Android");
        title.setTextSize(22);
        root.addView(title);
        TextView help = new TextView(this);
        help.setText("Selecione a pasta extraída do jogo. Ela deve conter Default.xex e os arquivos de dados do jogo. Os arquivos permanecem no local original.");
        help.setTextSize(16);
        root.addView(help);
        status = new TextView(this);
        status.setText("Aguardando seleção da pasta.");
        root.addView(status);
        Button pick = new Button(this);
        pick.setText("Selecionar pasta do jogo");
        pick.setOnClickListener(v -> beginPick());
        root.addView(pick);
        setContentView(root);
        String saved = getPreferences(0).getString("game_root", null);
        if (saved != null && new File(saved, "Default.xex").isFile()) launch();
    }

    private void beginPick() {
        if (Build.VERSION.SDK_INT >= 30 && !Environment.isExternalStorageManager()) {
            status.setText("Conceda acesso a todos os arquivos e volte para selecionar a pasta.");
            try {
                startActivity(new Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                    Uri.parse("package:" + getPackageName())));
            } catch (Exception e) {
                startActivity(new Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION));
            }
            return;
        }
        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT_TREE);
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION |
            Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION |
            Intent.FLAG_GRANT_PREFIX_URI_PERMISSION);
        startActivityForResult(intent, PICK_TREE);
    }

    @Override protected void onActivityResult(int request, int result, Intent data) {
        super.onActivityResult(request, result, data);
        if (request != PICK_TREE || result != RESULT_OK || data == null || data.getData() == null) return;
        Uri tree = data.getData();
        try { getContentResolver().takePersistableUriPermission(tree, Intent.FLAG_GRANT_READ_URI_PERMISSION); }
        catch (Exception ignored) {}
        String path = resolvePath(tree);
        if (path == null || !new File(path, "Default.xex").isFile()) {
            status.setText("Default.xex não foi encontrado na raiz da pasta selecionada.");
            return;
        }
        getPreferences(0).edit().putString("game_root", path).apply();
        File external = getExternalFilesDir(null);
        if (external != null) {
            try (java.io.FileWriter writer = new java.io.FileWriter(new File(external, "game_root.txt"))) {
                writer.write(path + "\n");
            } catch (Exception e) {
                status.setText("Falha ao salvar configuração: " + e.getMessage());
                return;
            }
        }
        launch();
    }

    private String resolvePath(Uri tree) {
        try {
            String id = DocumentsContract.getTreeDocumentId(tree);
            if (id == null) return null;
            int colon = id.indexOf(':');
            String volume = colon < 0 ? id : id.substring(0, colon);
            String relative = colon < 0 ? "" : id.substring(colon + 1);
            if ("primary".equalsIgnoreCase(volume)) {
                return relative.isEmpty() ? "/storage/emulated/0" : "/storage/emulated/0/" + relative;
            }
        } catch (Exception ignored) {}
        return null;
    }

    private void launch() {
        startActivity(new Intent(this, MainActivity.class));
        finish();
    }
}
