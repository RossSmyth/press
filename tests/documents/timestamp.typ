#if datetime.today().year() != 1970 {
  panic("Expect a 1970 Unix timestamp, instead got:" + datetime.today().display())
}
