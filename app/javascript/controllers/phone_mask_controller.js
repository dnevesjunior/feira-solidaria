import { Controller } from "@hotwired/stimulus"

// Máscara de telefone brasileiro, igual ao placeholder: (13) 99999-0001 ou
// (13) 3333-0001. Só melhora a digitação — o servidor normaliza qualquer
// formato (PhoneNumber), então o campo funciona sem JavaScript.
export default class extends Controller {
  connect() {
    this.format()
  }

  format() {
    const input = this.element
    let digits = input.value.replace(/\D/g, "")

    // Quem cola "+55 13 ..." não deve ficar com o 55 no DDD. (Digitar "+55"
    // tecla a tecla não é coberto: o "+" cai na primeira tecla e 55 é um DDD real.)
    if (digits.length > 11 && digits.startsWith("55")) digits = digits.slice(2)
    digits = digits.slice(0, 11)

    const ddd = digits.slice(0, 2)
    const rest = digits.slice(2)
    // 9 dígitos → celular (5-4); até 8 → fixo (4-4)
    const split = rest.length > 8 ? 5 : 4

    let out = ""
    if (ddd) out = digits.length > 2 ? `(${ddd}) ` : `(${ddd}`
    if (rest) out += rest.length > split ? `${rest.slice(0, split)}-${rest.slice(split)}` : rest

    input.value = out
  }
}
