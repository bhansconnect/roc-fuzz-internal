interface Arbitrary
    exposes [new, len, isEmpty, arbitraryByteSize, u64InInclusiveRange, bytes, ratio, arbitraryStr, arbitraryListU8]
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

arbitraryStr : Unstructured -> {value: Str, state: Unstructured}
arbitraryStr = \u1 ->
    {value: size, state: u2} = arbitraryByteSize u1
    {value: data, state: u3} =
        when bytes u2 size is
            Ok x -> x
            Err _ -> crash "byte range from arbitrary size must fit in data"

    {value: rawStr, state: u4} =
        when Str.fromUtf8 data is
            Ok value ->
                {value, state: u3}
            Err (BadUtf8 _ index) ->
                # Even though this failed, we can stil parse the utf8 up to this index.
                # we didn't use all bytes, so reclaim some of them.
                {value: altData, state: altU3} =
                    when bytes u2 index is
                        Ok x -> x
                        Err _ -> crash "byte range from arbitrary size must fit in data"
                when Str.fromUtf8 altData is
                    Ok value ->
                        {value, state: altU3}
                    Err _ -> crash "This subset of the string should be valid for conversion to utf8"

    # Allow the string to reserve an extra capacity up to the next power of 2 after the size.
    # For example, if size is 14, it can reserve upto a size of 32 (16 * 2).
    maxCap =
        tmp = 2 * (nextPowerOf2 (Str.countUtf8Bytes rawStr))
        # Ensure that we can always allocate past small string size of 24.
        if tmp < 32 then
            32
        else
            tmp
    {value: cap, state: u5} = u64InInclusiveRange u4 0 maxCap

    {
        value:
            if (Num.toNat cap) > Str.countUtf8Bytes rawStr then
                Str.reserve rawStr ((Num.toNat cap) - Str.countUtf8Bytes rawStr)
            else
                rawStr,
        state: u5,
    }

nextPowerOf2 = \n ->
    x = nextPowerOf2Helper n
    Num.shiftLeftBy 1 x

nextPowerOf2Helper = \n ->
    if n > 0 then
        1 + (nextPowerOf2Helper (Num.shiftRightZfBy n 1))
    else
        1

expect
    {value} =
        new [49, 50, 51, 52, 9]
        |> arbitraryStr
    value == "1234"

expect
    {value} =
        new [49, 50, 51, 52, 8]
        |> arbitraryStr
    value == "123"

expect
    {value} =
        new [49, 50, 51, 255, 9]
        |> arbitraryStr

    value == "123"

expect
    remaining =
        new [49, 50, 51, 255, 9]
        |> arbitraryStr
        |> .state
        |> \@Unstructured data -> data

    remaining == [255]

arbitraryListU8 : Unstructured -> {value: List U8, state: Unstructured}
arbitraryListU8 = \u1 ->
    # With a 50% prob make this a seamless slice.
    # Do this by droping the first element from the list.
    # Roc will the return a slice of the original list.
    {value: seamlessSlice, state: u2} = ratio u1 1 2

    {value: size, state: u3} = arbitraryByteSize u2
    {value: rawData, state: u4} =
        when bytes u3 size is
            Ok x -> x
            Err _ -> crash "byte range from arbitrary size must fit in data"

    # Allow the list to reserve an extra capacity up to the next power of 2 after the size.
    # For example, if size is 14, it can reserve upto a size of 32 (16 * 2).
    maxCap = 2 * (nextPowerOf2 (List.len rawData))
    {value: cap, state: u5} = u64InInclusiveRange u4 0 maxCap

    {
        value:
            (if (Num.toNat cap) > List.len rawData then
                List.reserve rawData ((Num.toNat cap) - List.len rawData)
            else
                rawData)
            |> \out -> if seamlessSlice then List.dropFirst out else out,
        state: u5,
    }


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
            # Take the byte from the end of the data.
            # This helps fuzzers more efficiently explore the input space.
            when List.last b is
                Ok x ->
                    next = Num.bitwiseOr (Num.shiftLeftBy current 8) (Num.toU64 x)
                    nextBytesConsumed = bytesConsumed + 1
                    if  (Num.shiftRightZfBy delta (8 * nextBytesConsumed) > 0) then
                        # still need to consume more data to fill delta.
                        genInt (List.dropLast b) next nextBytesConsumed
                    else
                        # consumed enough bytes to fill delta
                        {value: next, state: (List.dropLast b)}
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
    if List.len data >= requestedLen then
        {before, others} = List.split data (requestedLen + 1)
        Ok {value: before, state: @Unstructured others}
    else
        Err (NotEnoughData (List.len data))

ratio : Unstructured, U64, U64 -> { value: Bool, state: Unstructured }
ratio = \u, numerator, denominator ->
    if numerator > denominator then
        crash "numerator must be less than or equal to the denominator for ratio"
    else
        {value, state} = u64InInclusiveRange u 1 denominator
        # The next condition is weird to make it so a default value of 0 will be false.
        # instead of <= numerator, we have > denominator - numerator.
        {value: value > denominator - numerator, state}
        

