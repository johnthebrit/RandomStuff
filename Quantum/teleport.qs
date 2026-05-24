/// Quantum teleportation using the deferred measurement principle so that
/// the circuit can run on hardware that does not support mid-circuit
/// measurement or classical feed-forward.
///
/// Layout (matching the attached hand-drawn circuit):
///   c  : qubit carrying the state |psi> to be teleported
///   a  : Alice's half of the entangled pair |Phi+>
///   b  : Bob's half of the entangled pair |Phi+>
///
/// The classical-controlled X and Z corrections on Bob's qubit are
/// replaced by their quantum-controlled equivalents (CNOT(a,b) and
/// CZ(c,b)) and all measurements are deferred to the end of the circuit.
/// After teleportation, the Adjoint of the state-preparation routine is
/// applied to Bob's qubit; measuring it should always yield Zero.

import Std.Diagnostics.*;

/// State to teleport. Any single-qubit unitary applied to |0> works;
/// pick something non-trivial so the test is meaningful.
operation PreparePsi(q : Qubit) : Unit is Adj + Ctl {
    H(q);
    T(q);
    Rx(1.2345, q);
}

operation Main() : Result {
    use c = Qubit();
    use a = Qubit();
    use b = Qubit();

    // Prepare the state |psi> on c.
    PreparePsi(c);

    // Prepare the Bell pair |Phi+> on (a, b).
    H(a);
    CNOT(a, b);

    // Teleportation core (Bell-basis measurement on c, a -- deferred).
    CNOT(c, a);
    H(c);

    // Deferred-measurement corrections on b:
    // classical X conditioned on M(a) -> quantum CNOT(a, b)
    // classical Z conditioned on M(c) -> quantum CZ(c, b)
    CNOT(a, b);
    CZ(c, b);

    // Bob's qubit should now be in the state |psi>.
    // Un-prepare it; if teleportation succeeded, b is |0>.
    Adjoint PreparePsi(b);

    let result = M(b);

    // Tidy up the auxiliary qubits before releasing them.
    Reset(c);
    Reset(a);

    return result;
}
