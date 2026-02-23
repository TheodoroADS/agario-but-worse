module normal_distribution;


import std::math::random;
import std::math;

/*
Using the box-muller transform to create a number from a normal distribution
I heard about this online lol
The box-muller transform actually generates 2 numbers, so I store the spare one as a static variable
*/

// will have mean=0 and std=1
fn float sample_normal_normalized() {

    static bool has_spare = false;
    static float spare;

    if (has_spare) {
        has_spare = false;
        return spare;
    }

    float u1, u2;
    do {
        u1 = (float) rand(100000) / 100000;
    } while(u1 == 0.0f);
    u2 = (float) rand(100000) / 100000;

    float r =  math::sqrt(-2.0f * math::ln(u1));
    float theta = 2.0 * math::PI * u2;

    spare = r * math::sin(theta);
    has_spare = true;

    return r*math::cos(theta);
}


// for when we would like to modify mean and stds
fn float sample_normal(float mean, float std) {
    return mean + std*sample_normal_normalized();
}

