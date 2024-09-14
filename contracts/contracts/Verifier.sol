// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity ^0.8.0;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() pure internal returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() pure internal returns (G2Point memory) {
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
    }
    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) pure internal returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
    }


    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success);
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[1];
            input[i * 6 + 3] = p2[i].X[0];
            input[i * 6 + 4] = p2[i].Y[1];
            input[i * 6 + 5] = p2[i].Y[0];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alpha;
        Pairing.G2Point beta;
        Pairing.G2Point gamma;
        Pairing.G2Point delta;
        Pairing.G1Point[] gamma_abc;
    }
    struct Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }
    function verifyingKey() pure internal returns (VerifyingKey memory vk) {
        vk.alpha = Pairing.G1Point(uint256(0x28b244ce88f526643cd4ec708f1c95c4a8b5a1862ee9ddece3462674a75d2748), uint256(0x050000fb8667f28ba83a8957e4d3c60f6005d7ab48407f672b314c88dbe3d676));
        vk.beta = Pairing.G2Point([uint256(0x0ad6c796f46b99df01e917b4cecd73501426f7dd15e6c8f8acf30780617216f7), uint256(0x077613be370387524828e3ae1ba7c025b9e2d67652b3e19ebe5ccab3b84979c8)], [uint256(0x2e32365451476cada021f9eaa2dee87d6e313db851fa578bdbb72a45f6c32afb), uint256(0x19844901ce0a718d420628d11beef24233fcfa05a2123dab094f51d2743e3be6)]);
        vk.gamma = Pairing.G2Point([uint256(0x04a0404f3ea583009ca61b469409e029f87db2812a5c7701661e135d4e0523e5), uint256(0x16effe68b92b08898a75a8cb9d4750ffb5748599887bfa4bd1c2a9a8ccdea298)], [uint256(0x16793b24498c1601a76aecb7f36240e4dea6f221885aa7c8f94f0422413157c9), uint256(0x2d931bff6010a23ec5301e8a0047bfd95f55a7884a705a207040dcb50b1c6d78)]);
        vk.delta = Pairing.G2Point([uint256(0x2595b710beba5beaead01d6b2a8a418c638e15baa5bbfeadb2ad8eba04526fb5), uint256(0x1374df41d289b42de309d03d95fe5329f70c15fe304a0ff9d69abef17b6fdde0)], [uint256(0x19807c0552a73c5dcf908166623f7b3d2a35854340bdd4b8277c70d1a66922fb), uint256(0x25922d6524b57e69b87be136f88ed81fb38a96cf8e4be5116a77f5c87553fe12)]);
        vk.gamma_abc = new Pairing.G1Point[](18);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x122f1efcfcaa71f6876d2fd1d83457fcd529f7d72bd9592dc083394214a10f1b), uint256(0x255894f27838eb79fdf0121b84377f3ab7de55688d9165fcd003356b5720e2d0));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x28f64cfa1189da83de9bfe7340d765b8538046eb65a22eaf3d3467d18ac2f30f), uint256(0x226dd6adbf5612ca56b64bda53e5a0cd26ca998a904c884b5d1f4d9156c87d05));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x2e01a1b48add40e2a6bdeb18c63fc5a7f50cbe8faf5a5b0c4e4fead9a2654683), uint256(0x1834ace1f0e6cb66ee5f793dd5406aa81caadef908af0d1a77cea75620876efd));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x28401da452c162e9d9020806d4bfe2fff0a616b2e5118937db1117d0c0210eb4), uint256(0x2aa689236c67687352ca697c865987bb1df916e4f64f33ed8337050de949b7e6));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x2cbf7a580fcb09022b194c027a67fdf4c1c43732523d77f2de63ce75b4aeec53), uint256(0x1b33fb7a7e6304ee190e60bddd7df541667542539618b14f01fd83deec12ffb8));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x0efb5480c0c2b55dd9cad1c4091e72c99adae4e48b701edc6c611c2a010071ce), uint256(0x269d933790d1304ed4e49282433c5da8e969e50fb54ac06e4b2a069488958418));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x11094e2ee37fbacb25bac534d83396418793436b752bbefc9ae2998ec3013cb1), uint256(0x1b09ad3367bde9a208c63b35142db736fa4699c655ad6ac2689a75e7e0da51e1));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x00f0c7daf1f1ccf53b64c15ef8b356f2210aed440c22bbb091fb4aa814c661b5), uint256(0x27d59c4104f11a8e6fbb8274bec4a92fed4294ae03548356915eaf437161dc67));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x14d40e97a456fa7b0c815bbbbcf66fbebe0f751a63080bf606b55ffe95797a13), uint256(0x07127938e9998733558294f63a1a2d40d2063abf953ffbbd65cf8f82607fd9be));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x09aa8bc63c5513ad73b08c5ae5eb2c3937da5c42bb80ca0081645319cf95ac53), uint256(0x21fe1200e13e3e065232623a9a8f2c288b7a08bce2778179def961eec5c5bb9b));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x171f428998b1168420c178279a38637d4cd2ccf7fb15c6a4b524ad2696b26b59), uint256(0x1f5d75dce922d513fd8c0d8526dd4e9d8b568770da1b0314e89d99cb3d0ae747));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x20a540771917e97e67f5b4dc0aeac3641d8d8d3dbeec1c7de11c46f68ad8dbca), uint256(0x065157d490bae545421674804798a182024b5b4a50836e972c6298b3823ace55));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x18aa990caf5e5762af5e82d61f58dd83f094d30fec1e5ca50ff854de8741c90a), uint256(0x00c386999bc582d714b871dfaa9bfb0487f9184f6ecb34d9127048c59316314c));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x20bcf2cf9c7c9ac4b118b54364097ad5918faba36ae6b84a409ecd34e588f959), uint256(0x2179af88e60f29fe5b4d677b6a9fcedf8b397e4a173838c34dd282f948e4b118));
        vk.gamma_abc[14] = Pairing.G1Point(uint256(0x1709f5203350513e623966a1e746658eceea3368621639e5d8e691602ada0d67), uint256(0x1ed67dcf6043d22a3de42c469b069385983fb062533d6dbbcd989e4418ba01c3));
        vk.gamma_abc[15] = Pairing.G1Point(uint256(0x252458ac8899bb5bc067202a250a944a161826f291e4c962e36ceadb70eb9c41), uint256(0x11aa3fb37d87f55291fa2cc2c2cd203ba01ad4a9f52025fce2093804a9690ad9));
        vk.gamma_abc[16] = Pairing.G1Point(uint256(0x0dc96f4d68cd8cc5a6c571a9f478f0afcc32fd21316b18f6ba1ccdd6ea8a97f1), uint256(0x1b0fe521942b304f30ed41d1c25306a09e806b90533f6a97fc602ca35c1e4af2));
        vk.gamma_abc[17] = Pairing.G1Point(uint256(0x0df22f22b65187849e1d398d11691f2d986e0d1308789f7dd9ce9f827192c0ac), uint256(0x0b520b1df594a48d03999918883d6580bc4284c52903d59acec39112061255b2));
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.gamma_abc.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field);
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.gamma_abc[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.gamma_abc[0]);
        if(!Pairing.pairingProd4(
             proof.a, proof.b,
             Pairing.negate(vk_x), vk.gamma,
             Pairing.negate(proof.c), vk.delta,
             Pairing.negate(vk.alpha), vk.beta)) return 1;
        return 0;
    }
    function verifyTx(
            Proof memory proof, uint[17] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](17);
        
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
