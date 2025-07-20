const express = require('express');
const app = express();
const port = process.env.PORT || 8080;

app.get('/', (req, res) => {
  const message = process.env.SECRET_MESSAGE || "Đây là phiên bản mặc định.";
  res.send(`
    <h1>Chào mừng đến với Web App của tôi trên Azure!</h1>
    <p>Thông điệp bí mật được lấy từ Key Vault là: <strong>${message}</strong></p>
  `);
});

app.listen(port, () => {
  console.log(`Ứng dụng đang lắng nghe trên cổng ${port}`);
});