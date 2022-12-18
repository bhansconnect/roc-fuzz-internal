interface Arbitrary
    exposes [new, len, isEmpty, arbitraryByteSize, u64InInclusiveRange, bytes, ratio]
    imports []

Unstructured := List U8

new : List U8 -> Unstructured
new = \data -> @Unstructured data

len : Unstructured -> Nat
len = \@Unstructured data -> List.len data

expect
    u = new [1,2,3]

    len u == 3

isEmpty : Unstructured -> Bool
isEmpty = \u -> (len u) == 0

expect
    u = new [1,2,3]

    !(isEmpty u)

expect
    u = new []

    isEmpty u

# arbitrary : Unstructured -> Result a e | a has Arbitrary

# Requires size hints
# arbitraryLen : Unstructured -> Result usize

arbitraryByteSize : Unstructured -> {value: Nat, state: Unstructured}
arbitraryByteSize = \@Unstructured data ->
    if List.isEmpty data then
        { value: 0, state: @Unstructured data } 
    else if List.len data == 1 then
        { value: 0, state: new [] }
    else
        # Take the length from the end of the data.
        # This helps fuzzers more efficiently explore the input space.

        # We only consume as many bytes as necessary to cover the entire range of the byte string.
        # Note: We cast to u64 so we don't overflow when checking std::u32::MAX + 4 on 32-bit archs.
        dataLen = List.len data
        if Num.toU64 dataLen <= 0xFF + 1 then
            numBytes = 1
            maxLen = dataLen - numBytes
            {before, others} = List.split data maxLen
            {value} = u64InInclusiveRange (@Unstructured others) 0 (Num.toU64 maxLen)
            {value: Num.toNat value, state: @Unstructured before}
        else if Num.toU64 dataLen <= 0xFFFF + 1 then
            numBytes = 2
            maxLen = dataLen - numBytes
            {before, others} = List.split data maxLen
            {value} = u64InInclusiveRange (@Unstructured others) 0 (Num.toU64 maxLen)
            {value: Num.toNat value, state: @Unstructured before}
        else if Num.toU64 dataLen <= 0xFFFF_FFFF + 1 then
            numBytes = 4
            maxLen = dataLen - numBytes
            {before, others} = List.split data maxLen
            {value} = u64InInclusiveRange (@Unstructured others) 0 (Num.toU64 maxLen)
            {value: Num.toNat value, state: @Unstructured before}
        else
            numBytes = 8
            maxLen = dataLen - numBytes
            {before, others} = List.split data maxLen
            {value} = u64InInclusiveRange (@Unstructured others) 0 (Num.toU64 maxLen)
            {value: Num.toNat value, state: @Unstructured before}

expect
    {value} =
        new []
        |> arbitraryByteSize

    value == 0

expect
    {value} =
        new [2, 4, 5, 6, 9]
        |> arbitraryByteSize
    value == 4
    
expect
    {value} =
        new [2, 4, 5, 6, 9, 27]
        |> arbitraryByteSize
    value == 3

expect
    {value} =
        List.repeat 0 300
        |> List.append 77
        |> new 
        |> arbitraryByteSize
    value == 77

expect
    {value} =
        List.repeat 0 0x0FFF
        |> List.append 0x12
        |> List.append 0x34
        |> new 
        |> arbitraryByteSize
    value == 0x0234

expect
    {value} =
        List.repeat 0 0x2000
        |> List.append 0x12
        |> List.append 0x34
        |> new 
        |> arbitraryByteSize
    value == 0x1234

u64InInclusiveRange : Unstructured, U64, U64 -> {value: U64, state: Unstructured}
u64InInclusiveRange = \@Unstructured data, start, end ->
    if start > end then
        crash "intInInclusiveRange requires a non-empty range"
    else if start == end then
        # Don't waste entropy when there is only one option
        {value: start, state: @Unstructured data}
    else
        delta = Num.subWrap end start
        genInt = \b, current, bytesConsumed ->
            when List.first b is
                Ok x ->
                    next = Num.bitwiseOr (Num.shiftLeftBy current 8) (Num.toU64 x)
                    nextBytesConsumed = bytesConsumed + 1
                    if  (Num.shiftRightZfBy delta (8 * nextBytesConsumed) > 0) then
                        # still need to consume more data to fill delta.
                        genInt (List.dropFirst b) next nextBytesConsumed
                    else
                        # consumed enough bytes to fill delta
                        {value: next, state: b}
                Err _ ->
                    {value: current, state: b}
        int = genInt data 0 0
        offset =
            when Num.addChecked delta 1 is
                Ok y ->
                    int.value % y
                Err _ ->
                    # This will only happen when delta represents the entire integers range.
                    int.value
        result = Num.addWrap start offset

        { value: result, state: @Unstructured int.state }

expect
    new []
    |> u64InInclusiveRange 0 100
    |> .value
    |> Bool.isEq 0
    
bytes : Unstructured, Nat -> Result {value: List U8, state: Unstructured} [NotEnoughData Nat]
bytes = \@Unstructured data, requestedLen ->
    if List.len data>= requestedLen then
        {before, others} = List.split data requestedLen
        Ok {value: before, state: @Unstructured others}
    else
        Err (NotEnoughData (List.len data))

ratio : Unstructured, U64, U64 -> { value: Bool, state: Unstructured }
ratio = \u, numerator, denominator ->
    if numerator > denominator then
        crash "numerator must be less than or equal to the denominator for ratio"
    else
        {value, state} = u64InInclusiveRange u 1 denominator
        {value: value <= numerator, state}
        

