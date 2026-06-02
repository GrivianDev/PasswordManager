const googleResultPage = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Ethercrypt</title>

  <style>
    :root {
      color-scheme: dark;
    }

    body {
      margin: 0;
      background: #0f1115;
      color: #ffffff;
      font-family: Inter, system-ui, sans-serif;

      display: flex;
      align-items: center;
      justify-content: center;

      width: 100vw;
      height: 100vh;
    }

    .card {
      background: #181c23;
      border: 1px solid #2a2f3a;

      border-radius: 20px;

      padding: 40px;
      width: 420px;

      box-shadow:
        0 20px 60px rgba(0,0,0,0.4);
    }

    .header {
      display: flex;
      align-items: center;
      gap: 16px;
    }

    .icon {
      width: 52px;
      height: 52px;

      min-width: 52px;

      border-radius: 50%;

      background: #1f8bff;

      display: flex;
      align-items: center;
      justify-content: center;

      font-size: 28px;
      font-weight: bold;
    }

    h1 {
      margin: 0;
      font-size: 28px;
      font-weight: 700;
      line-height: 1.2;
    }

    .hint {
      margin-top: 24px;
      font-size: 13px;
      color: #7f8794;
    }
  </style>
</head>

<body>
  <div class="card">

    <div class="header">
      <div class="icon">✓</div>
      <h1>Google Drive connected to Ethercrypt</h1>
    </div>

    <div class="hint">
      You can safely close this window.
    </div>

  </div>
</body>
</html>
''';