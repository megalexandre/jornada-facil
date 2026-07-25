import 'dart:math';

/// Gera uma senha forte para o admin definir ao criar um funcionário. Usa
/// `Random.secure()` e garante ao menos um caractere de cada classe (maiúscula,
/// minúscula, dígito, símbolo). Exclui caracteres ambíguos (O/0, l/1) pra
/// facilitar a leitura/repasse. `length` deve ser >= 4.
String generateStrongPassword({int length = 16}) {
  const upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
  const lower = 'abcdefghijkmnopqrstuvwxyz';
  const digits = '23456789';
  const symbols = '!@#\$%&*?';
  final all = upper + lower + digits + symbols;
  final rnd = Random.secure();

  final chars = <String>[
    upper[rnd.nextInt(upper.length)],
    lower[rnd.nextInt(lower.length)],
    digits[rnd.nextInt(digits.length)],
    symbols[rnd.nextInt(symbols.length)],
  ];
  for (var i = chars.length; i < length; i++) {
    chars.add(all[rnd.nextInt(all.length)]);
  }
  chars.shuffle(rnd);
  return chars.join();
}
