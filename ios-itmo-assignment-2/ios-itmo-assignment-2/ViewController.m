#import "ViewController.h"
#import "ios_itmo_assignment_2-Swift.h"


//

@protocol CASGOLViewDelegate<NSObject>

@end

//

//

@interface CASGOLView: UIView

@property (nonatomic) CASGOLState *state;

@property (nonatomic, readonly) CATiledLayer *tiledLayer;

@property (nonatomic, readonly) CGRect globalFrame;

@end

//

@interface CASGOLView()

@end

@implementation CASGOLView

+ (Class)layerClass {
    return CATiledLayer.self;
}

- (CATiledLayer *)tiledLayer {
    return (id)self.layer;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame: frame];
    if (self) {
        [super setContentScaleFactor:1];
        self.tiledLayer.contents = nil;
        self.tiledLayer.levelsOfDetail = 1;
        self.tiledLayer.tileSize = CGSizeMake(10, 10);
        self.contentMode = UIViewContentModeRedraw;
        [self updateTileSize];
    }
    return self;
}

- (void)setContentScaleFactor:(CGFloat)contentScaleFactor {
    // do nothing
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self updateTileSize];
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    [self updateTileSize];
}

- (void)updateTileSize {
    CGFloat x = MAX(1, self.bounds.size.width / MAX(1, self.state.viewport.size.width));
    CGFloat y = MAX(1, self.bounds.size.height / MAX(1, self.state.viewport.size.height));
    self.tiledLayer.tileSize = CGSizeMake(x, y);
    [self invalidateIntrinsicContentSize];
    [self setNeedsDisplay];
}

- (void)setState:(CASGOLState *)state {
    NSString *keyPath = NSStringFromSelector(@selector(revision));
    [_state removeObserver:self forKeyPath:keyPath];
    [state addObserver:self forKeyPath:keyPath options:0 context:NULL];
    _state = state;
    [self updateTileSize];
}

- (void)drawRect:(CGRect)rect {
    CGSize tileSize = self.tiledLayer.tileSize;
    CGPoint origin = self.state.viewport.origin;
    CGPoint point = CGPointMake(
        origin.x + rect.origin.x / tileSize.width,
        origin.y + rect.origin.y / tileSize.height
    );

    [([self.state cellAtPoint:point] ? UIColor.blackColor : UIColor.whiteColor) set];
    UIRectFill(rect);
}

- (CGSize)intrinsicContentSize {
    CGSize size = self.state.viewport.size;
    return CGSizeMake(size.width * 30, size.height * 30);
}

- (CGRect)globalFrame {
    CGSize tileSize = self.tiledLayer.tileSize;
    CGRect viewport = self.state.viewport;
    CGRect globalFrame = CGRectMake(
        viewport.origin.x * tileSize.width,
        viewport.origin.y * tileSize.height,
        viewport.size.width * tileSize.width,
        viewport.size.height * tileSize.height
    );
    return globalFrame;
}

@end



@interface MainScreenViewController () <UIScrollViewDelegate>

@property (nonatomic, readonly) UIScrollView *scrollView;
@property (nonatomic, readonly) CASGOLView *golView;
@property (nonatomic) NSTimer *timer;

@end

@implementation MainScreenViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _scrollView = [[UIScrollView alloc] init];
    _golView = [[CASGOLView alloc] init];

    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.golView.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:self.scrollView];
    [self.scrollView addSubview:self.golView];
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;

    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],

        [self.scrollView.topAnchor constraintEqualToAnchor:self.golView.topAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.golView.leadingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.golView.bottomAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.golView.trailingAnchor],
    ]];

    self.scrollView.minimumZoomScale = 0.1;
    self.scrollView.maximumZoomScale = 10;
    self.scrollView.delegate = self;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.golView;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    CASGOLState *state = [CASGOLState new];
    [state setCell:YES atPoint:CGPointMake(0, 2)];
    [state setCell:YES atPoint:CGPointMake(1, 2)];
    [state setCell:YES atPoint:CGPointMake(2, 2)];
    [state setCell:YES atPoint:CGPointMake(2, 1)];
    [state setCell:YES atPoint:CGPointMake(1, 0)];
    self.golView.state = state.copy;

    CASGOLSimulator *simulator = [CASGOLSimulator new];

    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:1 block:^(NSTimer *timer) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [simulator simulateState:state forNumberOfGenerationsAhead:1 error:NULL];
            CASGOLState *stateCopy = state.copy;
            dispatch_async(dispatch_get_main_queue(), ^{
                self.golView.state = stateCopy;
            });
        });
    }];}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.timer invalidate];
    self.timer = nil;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGRect rect = CGRectUnion(self.golView.globalFrame, CGRectZero);

    UIEdgeInsets inset = UIEdgeInsetsMake(
        CGRectGetMaxY(rect),
        CGRectGetMaxX(rect),
        CGRectGetMinY(rect),
        CGRectGetMinX(rect)
    );

    self.scrollView.contentInset = inset;
    [self.golView setNeedsDisplay];
}

@end
