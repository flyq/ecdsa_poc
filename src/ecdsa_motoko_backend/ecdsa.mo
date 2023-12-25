import Int "mo:base/Int";
import Iter "mo:base/Iter";

module {
    /// Returns x, y, g such that g = x*a + y*b = gcd(a, b).
    public func igcdex(a : Int, b : Int) : (x : Int, y : Int, g : Int) {
        var a_ = a;
        var b_ = b;

        if (a_ == 0 and b_ == 0) {
            return (0, 1, 0);
        };

        if (a_ == 0) {
            return (0, b_ / Int.abs(b_), Int.abs(b_));
        };

        if (b_ == 0) {
            return (a_ / Int.abs(a_), 0, Int.abs(a_));
        };

        var x_sign : Int = 1;
        if (a_ < 0) {
            a_ := -a_;
            x_sign := -1;
        };

        var y_sign : Int = 1;
        if (b_ < 0) {
            b_ := -b_;
            y_sign := -1;
        };

        var x : Int = 1;
        var y : Int = 0;
        var r : Int = 0;
        var s : Int = 1;

        while (b_ != 0) {
            var c = a_ % b_;
            var q = a_ / b_;
            var r_ = r;
            var s_ = s;

            a_ := b_;
            b_ := c;
            r := x - q * r;
            s := y - q * s;
            x := r_;
            y := s_;
        };

        return (x * x_sign, y * y_sign, a_);
    };

    /// Finds a nonnegative integer x < p such that (m * x) % p == n.
    public func div_mod(n : Int, m : Int, p : Int) : Int {
        let (a, _, c) = igcdex(m, p);

        let x = if (a < 0) {
            a + p;
        } else { a };

        assert c == 1;
        return (n * x) % p;
    };

    /// Returns (x / y) % P
    public func bigint_div_mod(x : Int, y : Int, p : Int) : Int {
        let res = div_mod(x, y, p);
        return res;
    };

    /// Returns (x + y) % P
    public func bigint_add_mod(x : Int, y : Int, p : Int) : Int {
        let add = x + y;
        let res = bigint_div_mod(add, 1, p);
        return res;
    };

    /// Returns (x - y) % P
    public func bigint_sub_mod(x : Int, y : Int, p : Int) : Int {
        let sub = x - y;
        let res = bigint_div_mod(sub, 1, p);
        return res;
    };

    /// Returns (x * y) % P
    public func bigint_mul_mod(x : Int, y : Int, p : Int) : Int {
        let z = x * y;
        let res = bigint_div_mod(z, 1, p);
        return res;
    };

    public type EPoint = (x : Int, y : Int);

    /// Returns the slope of the elliptic curve at the given point.
    /// The slope is used to compute pt + pt.
    /// Assumption: pt != 0.
    public func compute_doubling_slope(pt : EPoint, sp : Int, sa : Int) : Int {
        let x_sqr = bigint_mul_mod(pt.0, pt.0, sp);
        let y_2 = 2 * pt.1;
        let slope = bigint_div_mod((3 * x_sqr + sa), y_2, sp);
        return slope;
    };

    /// Returns the slope of the line connecting the two given points.
    /// The slope is used to compute pt0 + pt1.
    /// Assumption: pt0.x != pt1.x (mod curve_prime).
    public func compute_slope(pt0 : EPoint, pt1 : EPoint, sp : Int) : Int {
        let x_diff = pt0.0 - pt1.0;
        let y_diff = pt0.1 - pt1.1;
        let slope = bigint_div_mod(y_diff, x_diff, sp);
        return slope;
    };

    /// Given a point 'pt' on the elliptic curve, computes pt + pt.
    public func ec_double(pt : EPoint, sp : Int, sa : Int) : EPoint {
        if (pt.0 == 0) {
            return pt;
        };

        let slope = compute_doubling_slope(pt, sp, sa);
        let slope_sqr = bigint_mul_mod(slope, slope, sp);

        let new_x = bigint_div_mod(slope_sqr - 2 * pt.0, 1, sp);
        let x_diff_slope = bigint_mul_mod(slope, (pt.0 - new_x), sp);
        let new_y = bigint_sub_mod(x_diff_slope, pt.1, sp);

        return (new_x, new_y);
    };

    // Adds two points on the elliptic curve.
    // Assumption: pt0.x != pt1.x (however, pt0 = pt1 = 0 is allowed).
    // Note that this means that the function cannot be used if pt0 = pt1
    // (use ec_double() in this case) or pt0 = -pt1 (the result is 0 in this case).
    public func fast_ec_add(pt0 : EPoint, pt1 : EPoint, sp : Int) : EPoint {
        if (pt0.0 == 0) {
            return pt1;
        };
        if (pt1.0 == 0) {
            return pt0;
        };

        let slope = compute_slope(pt0, pt1, sp);
        let slope_sqr = bigint_mul_mod(slope, slope, sp);
        let new_x = bigint_div_mod(slope_sqr - pt0.0 - pt1.0, 1, sp);
        let x_diff_slope = bigint_mul_mod(slope, (pt0.0 - new_x), sp);
        let new_y = bigint_sub_mod(x_diff_slope, pt0.1, sp);

        return (new_x, new_y);
    };

    // Same as fast_ec_add, except that the cases pt0 = ±pt1 are supported.
    public func ec_add(pt0 : EPoint, pt1 : EPoint, sp : Int, sa : Int) : EPoint {
        let x_diff = bigint_sub_mod(pt0.0, pt1.0, sp);
        if (x_diff != 0) {
            // pt0.x != pt1.x so we can use fast_ec_add.
            return fast_ec_add(pt0, pt1, sp);
        };

        let y_sum = bigint_add_mod(pt0.1, pt1.1, sp);
        if (y_sum == 0) {
            // pt0.y = -pt1.y, note that the case pt0 = pt1 = 0 falls into this branch as well.
            return (0, 0);
        } else {
            return ec_double(pt0, sp, sa);
        };
    };

    /// Do the transform: Point(x, y) -> Point(x, -y)
    public func ec_neg(pt : EPoint, sp : Int) : EPoint {
        let neg_y = bigint_sub_mod(0, pt.1, sp);
        return (pt.0, neg_y);
    };

    /// Get k's ith bit, start from right
    /// why not use bitwise op? see: https://github.com/dfinity/motoko/issues/2799
    public func bit(k : Int, i : Int) : Int {
        var k_ = k;
        var i_ = i;
        if (i_ == 0) {
            return Int.abs((k_ % 2));
        } else {
            while (i_ > 0) {
                k_ := k_ / 2;
                i_ := i_ - 1;
            };
            return Int.abs(k_ % 2);
        };
    };

    public func mult(P : EPoint, r : Int, sp : Int, sa : Int) : EPoint {
        var a = r;
        var R = (0 : Int, 0 : Int);
        var k = 256;

        for (i in Iter.revRange(k - 1, 0)) {
            R := ec_double(R, sp, sa);
            if (bit(a, i) == 1) {
                R := fast_ec_add(R, P, sp);
            };
        };
        return R;
    };

    ///  Verify a point lies on the curve.
    ///  y^2 = x^3 + ax + b
    public func verify_point(pt : EPoint, sp : Int, sa : Int, sb : Int) : Bool {
        let y_sqr = bigint_mul_mod(pt.1, pt.1, sp);
        let x_sqr = bigint_mul_mod(pt.0, pt.0, sp);
        let x_cub = bigint_mul_mod(x_sqr, pt.0, sp);
        let a_x = bigint_mul_mod(pt.0, sa, sp);
        let right1 = bigint_add_mod(x_cub, a_x, sp);
        let right = bigint_add_mod(right1, sb, sp);
        let diff = bigint_sub_mod(y_sqr, right, sp);
        return diff == 0;
    };

    /// Verifies that val is in the range [1, N).
    public func validate_signature_entry(val : Int, N : Int) : Bool {
        return val > 0 and val < N;
    };

    public class SECP256K1() {
        let SP : Int = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f;
        let SN : Int = 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141;
        let SA : Int = 0x0000000000000000000000000000000000000000000000000000000000000000;
        let SB : Int = 0x0000000000000000000000000000000000000000000000000000000000000007;
        let SGX : Int = 0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798;
        let SGY : Int = 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8;

        /// the prime
        public func get_curve_prime() : Int {
            return SP;
        };

        /// the order of the curve
        public func get_curve_order() : Int {
            return SN;
        };

        public func get_curve_a() : Int {
            return SA;
        };

        public func get_curve_b() : Int {
            return SB;
        };

        /// the Generator Point
        public func get_curve_gen() : EPoint {
            return (SGX, SGY);
        };

        /// the public key of a secret key
        public func pubkey(sk : Int) : EPoint {
            let G = get_curve_gen();
            return mult(G, sk, SP, SA);
        };

        /// sign a message hash with a secret key
        public func sign_ecdsa(sk : Int, k : Int, msg_hash : Int) : (r : Int, s : Int) {
            let G = get_curve_gen();

            let pg = mult(G, k, SP, SA);

            let r = bigint_mul_mod(pg.0, 1, SN);

            let r_sk = bigint_mul_mod(r, sk, SN);
            let m_rsk = bigint_add_mod(msg_hash, r_sk, SN);
            let s = bigint_div_mod(m_rsk, k, SN);
            return (r, s);
        };

        /// verify a signature
        public func verify_ecdsa(pubkey_pt : EPoint, msg_hash : Int, r : Int, s : Int) : Bool {
            if (not verify_point(pubkey_pt, SP, SA, SB)) {
                return false;
            };
            // check res is not the zero point.
            if (not validate_signature_entry(r, SN)) {
                return false;
            };
            if (not validate_signature_entry(s, SN)) {
                return false;
            };

            let G = get_curve_gen();

            // Compute u1 and u2.
            let u1 = bigint_div_mod(msg_hash, s, SN);

            let u2 = bigint_div_mod(r, s, SN);

            let gen_u1 = mult(G, u1, SP, SA);
            let pub_u2 = mult(pubkey_pt, u2, SP, SA);

            let res = ec_add(gen_u1, pub_u2, SP, SA);

            let diff = bigint_sub_mod(res.0, r, SP);

            return diff == 0;
        };
    };

    public class SECP256R1() {
        let SP : Int = 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF;
        let SN : Int = 0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551;
        let SA : Int = 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFC;
        let SB : Int = 0x5AC635D8AA3A93E7B3EBBD55769886BC651D06B0CC53B0F63BCE3C3E27D2604B;
        let SGX : Int = 0x6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296;
        let SGY : Int = 0x4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5;

        /// the prime
        public func get_curve_prime() : Int {
            return SP;
        };

        /// the order of the curve
        public func get_curve_order() : Int {
            return SN;
        };

        public func get_curve_a() : Int {
            return SA;
        };

        public func get_curve_b() : Int {
            return SB;
        };

        /// the Generator Point
        public func get_curve_gen() : EPoint {
            return (SGX, SGY);
        };

        /// the public key of a secret key
        public func pubkey(sk : Int) : EPoint {
            let G = get_curve_gen();
            return mult(G, sk, SP, SA);
        };

        /// sign a message hash with a secret key
        public func sign_ecdsa(sk : Int, k : Int, msg_hash : Int) : (r : Int, s : Int) {
            let G = get_curve_gen();

            let pg = mult(G, k, SP, SA);

            let r = bigint_mul_mod(pg.0, 1, SN);

            let r_sk = bigint_mul_mod(r, sk, SN);
            let m_rsk = bigint_add_mod(msg_hash, r_sk, SN);
            let s = bigint_div_mod(m_rsk, k, SN);
            return (r, s);
        };

        /// verify a signature
        public func verify_ecdsa(pubkey_pt : EPoint, msg_hash : Int, r : Int, s : Int) : Bool {
            if (not verify_point(pubkey_pt, SP, SA, SB)) {
                return false;
            };
            // check res is not the zero point.
            if (not validate_signature_entry(r, SN)) {
                return false;
            };
            if (not validate_signature_entry(s, SN)) {
                return false;
            };

            let G = get_curve_gen();

            // Compute u1 and u2.
            let u1 = bigint_div_mod(msg_hash, s, SN);
            let u2 = bigint_div_mod(r, s, SN);

            let gen_u1 = mult(G, u1, SP, SA);
            let pub_u2 = mult(pubkey_pt, u2, SP, SA);

            let res = ec_add(gen_u1, pub_u2, SP, SA);

            let diff = bigint_sub_mod(res.0, r, SP);

            return diff == 0;
        };
    };
};
