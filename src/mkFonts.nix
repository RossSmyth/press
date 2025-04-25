{
  fonts,
  name,

  buildEnv,
}:
buildEnv {
  name = name + "-fonts";
  paths = fonts;
}
