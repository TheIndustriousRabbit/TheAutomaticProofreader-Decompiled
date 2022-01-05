# TheAutomaticProofreader-Decompiled

A decompiled copy of The New Automatic Proofreader with comments.

Watch the video that breaks down how this works: https://www.youtube.com/watch?v=R8IWYauT-MU


## Decompile it yourself

### radare2

```
r2 -a6502 -m4443 ap_6502.prg
pD 166
```

### da65

```
da65 ap_6502.prg -o ap_decompiled.asm
```

## License

Ruby code is licensed MIT. The Automatic Proofreader code is not mine.
