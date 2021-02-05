#ifndef BIOAIR_H
#define BIOAIR_H


class bioair
{
public:
    bioair();
    enum BioAirNodeStateEnum
    {
        BACKBONE,
        DESTINATION,
        EXTRA,
        FREE,
        ORIGIN,
        ORPHAN,
        REINFORCE,
        TIP,
        UNKNOWN
    };
};

#endif // BIOAIR_H
