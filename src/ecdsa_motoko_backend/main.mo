import ecdsa "./ecdsa";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Debug "mo:base/Debug";

actor {
  public query func greet(name : Text) : async Text {
    return "Hello, " # name # "!";
  };

  public query func test_revRange() : async Bool {
    for (i in Iter.revRange(10, 0)) {
      Debug.print(Int.toText(i));
    };
    return true;
  };

  public query func test_igcdex() : async Bool {
    assert ecdsa.igcdex(2, 3) == (-1, 1, 1);
    assert ecdsa.igcdex(10, 12) == (-1, 1, 2);
    assert ecdsa.igcdex(100, 2004) == (-20, 1, 4);
    return true;
  };

  public query func test_secp256k1() : async Bool {
    let secp256k1 = ecdsa.SECP256K1();
    let (x, y) = secp256k1.get_curve_gen();
    assert x == 0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798;
    assert y == 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8;
    return true;
  };

  public query func test_secp256r11() : async Bool {
    let pkx = 0x209D386328994AF4BBF0FF8BB6CDBB0E87E01E2118B1C12B94C555A1726129C6;
    let pky = 0x76AC8F2FDA3A921BD3DCC1D2F0741B91DCD18D053A67A4ECE89761E64A0881B1;
    let pub = (pkx, pky);
    let secp256r1 = ecdsa.SECP256R1();

    let msg_hash1 = 0xCA1AD489AB60EA581E6C119CC39D94DDBFC5FAA0E178A23CA66202C8C2A72277;
    let r1 = 0x22C2921ACF3A393A0BBAF1F68EE7E02F8385FF60CA67C41A1DE3CFF3FDAA1A74;
    let s1 = 0x1878DBC4684DE3A63A5975325B467CDBA846B24D949322016FE4C8FD2C0862A1;
    assert secp256r1.verify_ecdsa(pub, msg_hash1, r1, s1);

    return true;
  };

  public query func test_secp256r12() : async Bool {
    let pkx = 0x209D386328994AF4BBF0FF8BB6CDBB0E87E01E2118B1C12B94C555A1726129C6;
    let pky = 0x76AC8F2FDA3A921BD3DCC1D2F0741B91DCD18D053A67A4ECE89761E64A0881B1;
    let pub = (pkx, pky);
    let secp256r1 = ecdsa.SECP256R1();

    let msg_hash2 = 0x0F1AE6C77FEE73F3AC9BE1217F50C576C07D7E5FAA0E178A232DD33D09FF2CDE;
    let r2 = 0xB9201D2D40D63EB41D934C9D45280837CA09B03C4E063946CAA06EABEAACB944;
    let s2 = 0xBA69F449ED11E3677AB37367D99EC3B399A006FE875941F5DA57156A8FE9C8E0;

    assert secp256r1.verify_ecdsa(pub, msg_hash2, r2, s2);

    return true;
  };
};
